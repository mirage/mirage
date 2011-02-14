(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>

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
  callback: conn_id -> Request.request -> string Lwt_stream.t Lwt.t;
  conn_closed : conn_id -> unit;
  port: int;
  exn_handler: exn -> unit Lwt.t;
  timeout: float option;
}

exception Http_daemon_failure of string

  (** internal: given a status code and an additional body return a string
  representing an HTML document that explains the meaning of given status code.
  Additional data can be added to the body via 'body' argument *)
let control_body code body =
  let reason_phrase = Misc.reason_phrase_of_code code in
  sprintf "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\"><HTML><HEAD><TITLE>%d %s</TITLE></HEAD><BODY><H1>%d - %s</H1>%s</BODY></HTML>" code reason_phrase code reason_phrase body

let respond_with response =
  return (Response.serialize_to_stream response)

  (* Warning: keep default values in sync with Response.response class *)
let respond ?(body = "") ?(headers = []) ?version ?(status = `Code 200) () =
  let headers = ("connection","close")  :: headers  in
  let resp = Response.init ~body:[`String body] ~headers ?version ~status () in
  respond_with resp

let respond_control
    func_name ?(is_valid_status = fun _ -> true) ?(headers=[]) ?(body="")
    ?version status =
  let code = match status with `Code c -> c | #status as s -> code_of_status s in
  if is_valid_status code then
    let headers =
      [ "Content-Type", "text/html; charset=iso-8859-1" ] @ headers
    in
    let body = (control_body code body) ^ body in
      respond ?version ~status ~headers ~body ()
  else
    failwith
      (sprintf "'%d' isn't a valid status code for %s" code func_name)
      
let respond_redirect ~location ?body ?version ?(status = `Code 301) () =
  respond_control "Daemon.respond_redirect" ~is_valid_status:is_redirection
    ~headers:["Location", location] ?body ?version status

let respond_error ?body ?version ?(status = `Code 400) () =
  respond_control "Daemon.respond_error" ~is_valid_status:is_error
    ?body ?version status
    
let respond_not_found ~url ?version () =
  respond_control "Daemon.respond_not_found" ?version (`Code 404)
    
let respond_forbidden ~url ?version () =
  respond_control "Daemon.respond_forbidden" ?version (`Code 403)
    
let respond_unauthorized ?version ?(realm = server_string) () =
  let body =
    sprintf "401 - Unauthorized - Authentication failed for realm \"%s\"" realm
  in
    respond ~headers:["WWW-Authenticate", sprintf "Basic realm=\"%s\"" realm]
      ~status:(`Code 401) ~body ()

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
        debug_print (sprintf "HTTP request parse error: %s" (Printexc.to_string e));
        respond_error ~status ~body ()
    | None ->
        fail e

  (** - handle HTTP authentication
   *  - handle automatic closures of client connections *)
let invoke_callback conn_id (req:Request.request) spec =
  try_lwt 
    (match (spec.auth, (Request.authorization req)) with
     |`None, _ -> (* no auth required *)
       spec.callback conn_id req
     |`Basic (realm, authfn), Some (`Basic (username, password)) ->
       if authfn username password then
         spec.callback conn_id req (* auth ok *)
       else
         fail (Unauthorized realm)  (* auth failed *)
     |`Basic (realm, _), _ -> fail (Unauthorized realm)
    )
  with
    |Unauthorized realm -> respond_unauthorized ~realm ()
    |exn ->
      respond_error ~status:`Internal_server_error
        ~body:(Printexc.to_string exn) ()

let daemon_callback spec =
  let conn_id = ref 0 in
  let daemon_callback channel =
    let conn_id = incr conn_id; !conn_id in

    let streams, push_streams = Lwt_stream.create () in
    let write_streams =
      try_lwt
        Lwt_stream.iter_s (fun stream_t ->
          lwt stream = stream_t in
          Lwt_stream.iter_s (Net.Channel.TCPv4.write_string channel) stream >>
          Net.Channel.TCPv4.flush channel (* TODO: autoflush *)
        ) streams
      with exn -> begin
        Printf.printf "daemon_callback: exn %d: %s\n%!"
          conn_id (Printexc.to_string exn);
        return ()
      end
    in
    let rec loop () =
      try_lwt
        let finished_t, finished_u = Lwt.wait () in
        let stream =
          try_lwt
            let input_line () = Net.Channel.TCPv4.read_line channel in
            lwt req = Request.init_request finished_u input_line in
            invoke_callback conn_id req spec
          with e -> begin
            try_lwt
              lwt s = handle_parse_exn e in
              wakeup finished_u (); (* read another request *)
              return s
            with e ->
              wakeup_exn finished_u e;
              fail e
          end
        in
        push_streams (Some stream);
        finished_t >>= loop (* wait for request to finish before reading another *)
      with
        | End_of_file -> debug_print "done with connection"; spec.conn_closed conn_id; return ()
        | Canceled -> debug_print "cancelled"; spec.conn_closed conn_id; return ()
        | e -> fail e
    in
    try_lwt
      loop () <&> write_streams
    with
      | exn ->
	  debug_print (sprintf "uncaught exception: %s" (Printexc.to_string exn));
          (* XXX perhaps there should be a higher-level exn handler for 500s *)
	  spec.exn_handler exn
  in
  daemon_callback

let main mgr src spec =
  Net.Flow.TCPv4.listen mgr src (fun dst t ->
    let channel = Net.Channel.TCPv4.create t in
    match spec.timeout with
    |None -> 
      daemon_callback spec channel
    |Some tm ->
      let timeout_t = OS.Time.sleep tm in
      let callback_t = daemon_callback spec channel in
      timeout_t <?> callback_t
  )
