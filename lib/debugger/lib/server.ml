(*
 * Copyright (C) 2010 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

open Lwt
open Cow
open Net.Http.Daemon
open Net.Http.Request

let section = "Debugger.Server"

(* handle exceptions with a 500 *)
let exn_handler exn =
  let body = Printexc.to_string exn in
  Log.error section "ERROR: %s" body;
  return ()

(* main callback function *)
let dispatch conn_id req =
  let path_elem = path req in
  let path_elem = Str.split (Str.regexp_string "/") path_elem in
  let dyn ?(headers=[]) req body =
    let status = `OK in
    respond ~body ~headers ~status () in
  let static p =
    match Static.t p with
      | None      -> failwith (p ^ ": not found")
      | Some body -> respond ~body () in
  match path_elem with
    | []
    | ["index.html"]  -> static "index.html"
    | ["events"]      ->
      let last_id =
        try Some (int_of_string (List.hd (header req ~name:"last-event-id")))
        with _ -> None in
      let headers = ["content-type","text/event-stream"] in
      dyn ~headers req (Event.stream last_id)
    | ["index.css"]   -> dyn req Style.main
    | ["index.js"]    -> static "index.js"
    | x -> (respond_not_found ~url:(path req) ())

let spec = {
  address = "0.0.0.0";
  auth = `None;
  callback = dispatch;
  conn_closed = (fun _ -> ());
  port = 8081;
  exn_handler = exn_handler;
  timeout = Some 300.;
}

let _ =
  OS.Main.set_control_thread ( 
    Log.info section "listening to HTTP on port %d" spec.port;
    main spec
  )
