(* Simple hello world webserver *)

open Printf
open Lwt

let auth = `None

let conn_closed id =
  ()

let port = 8081

let callback id req =
  Http.Server.respond ~body:"hello mirage world"
    ~headers:["x-foo","bar"] () 

let exn_handler exn =
  printf "exn: %s\n%!" (Printexc.to_string exn);
  return ()

let spec = {
  Http.Server.address="foo";
  auth = `None;
  callback;
  conn_closed;
  port;
  exn_handler;
  timeout= None
}

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  let src = None,port in (* Listen on all interfaces *)
  Http.Server.listen mgr (`TCPv4 (src, spec))

let _ =
  OS.Main.run (main ())

