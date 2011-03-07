(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009-2011> Anil Madhavapeddy <anil@recoil.org>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Library General Public License as
  published by the Free Software Foundation, version 2.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
  USA
*)
open Printf

open Common
open Types
open Constants
open Parser

open Lwt

type conn_id = int
let string_of_conn_id = string_of_int

type daemon_spec = {
  address: string;
  auth: auth_info;
  callback: conn_id -> Request.request -> (Net.Channel.t -> unit Lwt.t) Lwt.t;
  conn_closed : conn_id -> unit;
  port: int;
  exn_handler: exn -> unit Lwt.t;
  timeout: float option;
}

(** internal: given a status code and an additional body return a string
  representing an HTML document that explains the meaning of given status code.
  Additional data can be added to the body via 'body' argument *)
let control_body code body =
  let reason_phrase = Misc.reason_phrase_of_code code in
  sprintf "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\"><HTML><HEAD><TITLE>%d %s</TITLE></HEAD><BODY><H1>%d - %s</H1>%s</BODY></HTML>" code reason_phrase code reason_phrase body

let respond_with response =
  return (Response.serialize_to_channel response)

(* Warning: keep default values in sync with Response.response class *)
let respond ?(body = "") ?(headers = []) ?version ?(status = `Code 200) () =
  let resp = Response.init ~body:[`String body] ~headers ?version ~status () in
  respond_with resp

let respond_control func_name ?(is_valid_status = fun _ -> true) ?(headers=[]) ?(body="") ?version status =
  let code = match status with `Code c -> c | #status as s -> code_of_status s in
  if is_valid_status code then
    let headers = [ "Content-Type", "text/html; charset=iso-8859-1" ] @ headers in
    let body = (control_body code body) ^ body in
    respond ?version ~status ~headers ~body ()
  else
    failwith (sprintf "'%d' isn't a valid status code for %s" code func_name)
      
let respond_redirect ~location ?body ?version ?(status = `Code 301) () =
  respond_control "Daemon.respond_redirect" ~is_valid_status:is_redirection ~headers:["Location", location] ?body ?version status

let respond_error ?body ?version ?(status = `Code 400) () =
  respond_control "Daemon.respond_error" ~is_valid_status:is_error ?body ?version status
    
let respond_not_found ~url ?version () =
  respond_control "Daemon.respond_not_found" ?version (`Code 404)
    
let respond_forbidden ~url ?version () =
  respond_control "Daemon.respond_forbidden" ?version (`Code 403)
    
let respond_unauthorized ?version ?(realm = server_string) () =
  let body = sprintf "401 - Unauthorized - Authentication failed for realm \"%s\"" realm in
  respond ~headers:["WWW-Authenticate", sprintf "Basic realm=\"%s\"" realm] ~status:(`Code 401) ~body ()

let handle_parse_exn e =
  let r =
    match e with
      | Malformed_request req ->
          Some
            (`Code 400,
             ("request 1st line format should be: " ^
		"'&lt;method&gt; &lt;url&gt; &lt;version&gt;'" ^
		"<br />\nwhile received request 1st line was:<br />\n" ^ req))
      | Invalid_HTTP_method meth ->
          Some
	    (`Code 501,
             ("Method '" ^ meth ^ "' isn't supported (yet)"))
      | Malformed_request_URI uri ->
          Some
            (`Code 400,
             ("Malformed URL: '" ^ uri ^ "'"))
      | Invalid_HTTP_version version ->
          Some
            (`Code 505,
	     ("HTTP version '" ^ version ^ "' isn't supported (yet)"))
      | Malformed_query query ->
          Some
            (`Code 400,
             (sprintf "Malformed query string '%s'" query))
      | Malformed_query_part (binding, query) ->
	  Some
            (`Code 400,
             (sprintf "Malformed query part '%s' in query '%s'" binding query))
      | _ -> None in

    match r with
    | Some (status, body) ->
        printf "HTTP request parse error: %s\n%!" (Printexc.to_string e);
        respond_error ~status ~body ()
    | None ->
        fail e

let daemon_callback spec =
  let conn_id = ref 0 in
  let daemon_callback channel =
    let conn_id = incr conn_id; !conn_id in
    let streams, push_streams = Lwt_stream.create () in
    let write_streams =
      try_lwt
        Lwt_stream.iter_s (fun outfn ->
          outfn channel >>
          Net.Channel.flush channel (* TODO: autoflush *) 
        ) streams
      with exn -> begin
        printf "daemon_callback: exn %d: %s\n%!" conn_id (Printexc.to_string exn);
        return ()
      end
    in
    let rec loop () =
      try_lwt
        let finished_t, finished_u = Lwt.wait () in
        let stream_t =
          try_lwt
            let read_line () =
              let stream = Net.Channel.read_crlf channel in
              lwt ts = OS.Istring.ts_of_stream stream in
              return (OS.Istring.ts_to_string ts)
            in
            lwt req = Request.init_request finished_u read_line in
            spec.callback conn_id req
          with e -> begin
            try_lwt
              lwt s = handle_parse_exn e in
              wakeup finished_u (); (* read another request *)
              return s
            with
             |e ->
              wakeup_exn finished_u e;
              fail e
            end
        in
        lwt stream =
          try_lwt
            lwt s = stream_t in
            return (Some s) 
          with Net.Nettypes.Closed -> return None in
        push_streams stream;
        finished_t >>= loop (* wait for request to finish before reading another *)
      with
        | Net.Nettypes.Closed -> return (spec.conn_closed conn_id)
        | Canceled -> return (spec.conn_closed conn_id)
        | e -> fail e
      in
      try_lwt
        loop () <&> write_streams
      with exn ->
	printf "HTTP: uncaught exception: %s\n%!" (Printexc.to_string exn);
        (* XXX perhaps there should be a higher-level exn handler for 500s *)
	spec.exn_handler exn
  in
  daemon_callback

let with_timeout tm fn t =
  match tm with
  |None -> fn t
  |Some tm -> fn t <?> (OS.Time.sleep tm)

let listen mgr sa =
  let cb spec dst = with_timeout spec.timeout (daemon_callback spec) in
  match sa with
    |`TCPv4 (src,spec) -> Net.Channel.listen mgr (`TCPv4 (src, cb spec))
    |`Pipe (src,spec) -> Net.Channel.listen mgr (`Pipe (src,cb spec))
    |`Shmem (src,spec) -> Net.Channel.listen mgr (`Shmem (src,cb spec))
