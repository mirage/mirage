(* Need a webserver server to works -- like http://jwebsocket.org/ *)

module OS = Browser

open Lwt

let nb_cons = 10
let ws_server = "ws://localhost:8080"

type connection = {
  mutable con : OS.Websocket.t option;
  mutable messages : int;
}

let empty_connection _ = { con = None; messages = 0 }

let cons = Array.init nb_cons empty_connection

let log = OS.Console.printf

let init () =
  for_lwt i = 0 to nb_cons - 1 do
    lwt con = OS.Websocket.create ws_server i in
    return (cons.(i).con <- Some con)
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
      log "[%d|%s] Sending %d bytes: <%s>" i id (String.length str) str;
      OS.Websocket.write con str
    | None     ->
      log "[%d|%s] WebSocket not initialized" i id

let random_read i id =
	match cons.(i).con with
	  | Some con ->
      log "[%i|%s] Reading ..." i id;
      lwt str = OS.Websocket.read con in
      cons.(i).messages <- cons.(i).messages - 1;
      log "[%i|%s] Read %d bytes: <%s>" i id (String.length str) str;
      return ()
    | None    ->
      log "[%d|%s] WebSocket not initialized" i id;
      return ()

let rec iter id n =
  let i = Random.int nb_cons in
  log "[%d|%s] iter %n" i id n;
  if n <= 0 then
    return ()
  else
    if cons.(i).messages > 0 && Random.int 2 = 0 then
      ( random_read i id >> iter id (n-1) )
    else
      ( random_write i id; iter id (n-1) )

let main () =
  try_lwt 
    init () >>
    join [iter "one" 10; iter "two" 15; iter "three" 10; iter "four" 15] >>
    return ()
  with OS.Websocket.Not_supported ->
    return (OS.Console.printf "[ERROR] Websockets are not supported by this browser")

let _ =
  OS.Main.run (main ())
