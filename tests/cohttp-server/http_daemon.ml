(*pp camlp4o -I `ocamlfind query lwt.syntax` pa_lwt.cmo *)

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

open Cohttp
open Http_common
open Http_types
open Http_constants
open Http_parser

open Lwt

type conn_id = int
let string_of_conn_id = string_of_int

type daemon_spec = {
  address: string;
  auth: auth_info;
  callback: conn_id -> Http_request.request -> string Lwt_stream.t Lwt.t;
  conn_closed : conn_id -> unit;
  port: int;
  root_dir: string option;
  exn_handler: exn -> unit Lwt.t;
  timeout: float option;
  auto_close: bool;
}

exception Http_daemon_failure of string

  (** internal: given a status code and an additional body return a string
  representing an HTML document that explains the meaning of given status code.
  Additional data can be added to the body via 'body' argument *)
let control_body code body =
  let reason_phrase = Http_misc.reason_phrase_of_code code in
  sprintf
"<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">
<HTML><HEAD>
<TITLE>%d %s</TITLE>
</HEAD><BODY>
<H1>%d - %s</H1>%s
</BODY></HTML>"
    code reason_phrase code reason_phrase body

let respond_with response =
  Lwt.return (Http_response.serialize_to_stream response)

  (* Warning: keep default values in sync with Http_response.response class *)
let respond ?(body = "") ?(headers = []) ?version ?(status = `Code 200) () =
  let resp = Http_response.init ~body:[`String body] ~headers ?version ~status () in
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

let respond_file ~fname ?droot ?(version = default_version) 
    ?(mime_type = "application/octet-stream") () =
  (** ASSUMPTION: 'fname' doesn't begin with a "/"; it's relative to the current
      document root (usually the daemon's cwd) *)
  debug_print "respond_file";
  let root = match droot with
    | Some s -> s
    | None   -> "root" in
  let path = root ^ "/" ^ fname in (* full path to the desired file *)
  let static = Printf.sprintf "<html><body><h1>Hello World</h1><p>%s</p></body></html>" path in
  let resp = Http_response.init ~body:[`String static] ~status:(`Code 200) ~version () in
  respond_with resp
      
(** internal: this exception is raised after a malformed request has been read
    by a serving process to signal main server (or itself if mode = `Single) to
    skip to next request *)
exception Again;;

  (* given a Http_parser.parse_request like function, wrap it in a function that
  do the same and additionally catch parsing exception sending HTTP error
  messages back to client as needed. Returned function raises Again when it
  encounter a parse error (name 'Again' is intended for future versions that
  will support http keep alive signaling that a new request has to be parsed
  from client) *)

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

  (* TODO what happens when a Quit exception is raised by a callback? Do other
  callbacks keep on living until the end or are they all killed immediately?
  The right semantics should obviously be the first one *)


  (** - handle HTTP authentication
   *  - handle automatic closures of client connections *)
let invoke_callback conn_id (req:Http_request.request) spec =
  try_lwt 
    (match (spec.auth, (Http_request.authorization req)) with
       | `None, _ -> spec.callback conn_id req (* no auth required *)
       | `Basic (realm, authfn), Some (`Basic (username, password)) ->
	   if authfn username password then spec.callback conn_id req (* auth ok *)
	   else fail (Unauthorized realm)
       | `Basic (realm, _), _ -> fail (Unauthorized realm)) (* auth failure *)
  with
    | Unauthorized realm -> respond_unauthorized ~realm ()
    | e ->
        respond_error ~status:`Internal_server_error ~body:(Printexc.to_string e) ()

let daemon_callback spec =
  let conn_id = ref 0 in
  let daemon_callback ~clisockaddr ~srvsockaddr flow =
    let conn_id = incr conn_id; !conn_id in

    let streams, push_streams = Lwt_stream.create () in
    let write_streams =
      catch
        (fun () ->
           Lwt_stream.iter_s
             (fun stream -> stream >>= Lwt_stream.iter_s (fun s -> let _ = debug_print s in OS.Flow.write_all flow s))
             streams)
        (fun _ -> Lwt.return ()) in

    let rec loop () =
      catch (fun () -> 
        debug_print "request";
        let (finished_t, finished_u) = Lwt.wait () in

        let stream =
          try_bind
            (fun () -> Http_request.init_request ~clisockaddr ~srvsockaddr finished_u flow)
            (fun req ->
               debug_print "invoke_callback";
               invoke_callback conn_id req spec)
            (fun e ->
               try_bind
                 (fun () -> handle_parse_exn e)
                 (fun s ->
                    Lwt.wakeup finished_u (); (* read another request *)
                    Lwt.return s)
                 (fun e ->
                    Lwt.wakeup_exn finished_u e;
                    Lwt.fail e)) in
        push_streams (Some stream);

        finished_t >>= loop (* wait for request to finish before reading another *)
      ) ( function 
         | End_of_file -> debug_print "done with connection"; spec.conn_closed conn_id; return ()
         | Canceled -> debug_print "cancelled"; spec.conn_closed conn_id; return ()
         | e -> fail e )
    in
    debug_print "server starting";
    try_lwt
      loop () <&> write_streams
    with
      | exn ->
	  debug_print (sprintf "uncaught exception: %s" (Printexc.to_string exn));
          (* XXX perhaps there should be a higher-level exn handler for 500s *)
	  spec.exn_handler exn
  in
  daemon_callback

let main spec =
  lwt srvsockaddr = Http_misc.build_sockaddr (spec.address, spec.port) in
  OS.Flow.listen (fun clisockaddr flow ->
      match spec.timeout with
      |None -> daemon_callback spec ~clisockaddr ~srvsockaddr flow
      |Some tm -> daemon_callback spec ~clisockaddr ~srvsockaddr flow <?> (OS.Time.sleep tm)
  ) srvsockaddr

module Trivial =
  struct
    let heading_slash str = str <> ""

    let callback _ req =
      let path = Http_request.path req in
      debug_print ("trivial_callback " ^ path);
      if not (heading_slash path) then
        respond_error ~status:(`Code 400) ()
      else
        respond_file ~fname:path ()

   let exn_handler exn =
     debug_print "no handler given: ignoring";
     return ()

   let conn_closed conn_id =
     debug_print "Connection closed"

   let spec = {
     address = "0.0.0.0";
     auth = `None;
     auto_close = false;
     callback = callback;
     conn_closed = conn_closed;
     port = 8080;
     root_dir = None;
     exn_handler = exn_handler;
     timeout = Some 300.;
   }
  end

let _ =
  let spec = Trivial.spec in
  debug := true;
  OS.Main.run ( 
    Log.logmod "Server" "listening to HTTP on port %d" spec.port;
    main spec
  )

