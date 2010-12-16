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

let filename = "server.ml"

(* handle exceptions with a 500 *)
let exn_handler exn =
  let body = Printexc.to_string exn in
  Log.debug ~filename "ERROR: %s" body;
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
    | ["events"]      -> dyn req (Event.stream ())
    | ["index.css"]   -> dyn req Style.main
    | ["index.js"]    -> static "index.js"
    | x -> (respond_not_found ~url:(path req) ())

let spec = {
  address = "0.0.0.0";
  auth = `None;
  callback = dispatch;
  conn_closed = (fun _ -> ());
  port = 6666;
  exn_handler = exn_handler;
  timeout = Some 300.;
}

let _ =
  OS.Main.set_control_thread ( 
    Printf.printf "listening to HTTP on port %d" spec.port;
    main spec
  )
