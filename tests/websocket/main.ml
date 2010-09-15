(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(*
  Need a websocket server to make this test works.
  A nice one is available at:
  http://github.com/miksago/node-websocket-server

  once node.js and node-websocket-server installed, on an other terminal write:
  sudo node examples/echo-server.js
*)

module OS = Browser

open Lwt

let nb_cons = 1
let ws_server = "ws://localhost:8000"

type connection = {
  mutable con : OS.Websocket.t option;
  mutable id : string;
  mutable messages : int;
}

let empty_connection _ = { con = None; id = "<empty>"; messages = 0 }

let cons = Array.init nb_cons empty_connection

let log = OS.Console.printf

let init () =
  for_lwt i = 0 to nb_cons - 1 do
    (* This will block until the connection is up *)
    lwt con = OS.Websocket.create ws_server i in
    (* When the connection is up, the echo server should send back the connection ID *)
    lwt id  = OS.Websocket.read con in
    log "[%i] %s" i id;
    cons.(i).con <- Some con;
    cons.(i).id  <- id;
    return ()
  done

let random_string () =
  let str = String.create (Random.int 2048) in
  for i = 0 to String.length str - 1 do
    str.[i] <- char_of_int (97 + Random.int 25)
  done;
  str

let random_write i id =
  match cons.(i).con with
    | Some con ->
      let str = random_string () in
      cons.(i).messages <- cons.(i).messages + 1;
      log "[%d|%s] Sending %d bytes: %s" i id (String.length str) str;
      OS.Websocket.write con str
    | None     ->
      log "[%d|%s] WebSocket not initialized" i id

let random_read i id =
	match cons.(i).con with
	  | Some con ->
      log "[%i|%s] Reading ..." i id;
      lwt str = OS.Websocket.read con in
      cons.(i).messages <- cons.(i).messages - 1;
      log "[%i|%s] Read %d bytes: %s" i id (String.length str) str;
      return ()
    | None    ->
      log "[%d|%s] WebSocket not initialized" i id;
      return ()

let iter id n =
  for_lwt j = 0 to n do
    OS.Time.sleep 1. >>
    let i = Random.int nb_cons in
    if cons.(i).messages > 0 && (j mod 2) = 1 (*Random.int 5 <> 0*) then
      random_read i id
    else
      return (random_write i id)
  done
   

let main () =
  try_lwt 
    init () >>
    join [iter "one" 10] >> (*; iter "two" 15; iter "three" 10; iter "four" 15] >>*)
    return ()
  with OS.Websocket.Not_supported ->
    return (OS.Console.printf "[ERROR] Websockets are not supported by this browser")

let _ =
  OS.Main.run (main ())
