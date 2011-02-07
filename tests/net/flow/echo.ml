(* Simple echo server that listens on 8081 and sends back everything it reads *)

open Lwt
open Printf
open Net

module F = Flow.TCPv4

let echo () =
  lwt mgr = Manager.create () in
  (* Listen on all interfaces, port 8081 *)
  let src = (None, 8081) in 
  F.listen mgr src
    (fun (remote_addr, remote_port) t ->
       OS.Console.log (sprintf "Connection from %s:%d"
         (Nettypes.ipv4_addr_to_string remote_addr) remote_port);
       let rec echo () =
         lwt res = F.read t in
         match res with
         |None ->
           OS.Console.log "Connection closed";
           return ()
         |Some data ->
           F.write t data >>
           echo ()
       in
       echo ()
    )

let _ = OS.Main.run (echo ())
