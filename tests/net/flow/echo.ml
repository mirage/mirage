(* Simple echo server that listens on 8081 and sends back everything it reads *)

open Lwt
open Printf
open Net

let rec watchdog () =
  let open Gc in
  Gc.compact ();
  let s = stat () in
  printf "blocks: l=%d f=%d\n%!" s.live_blocks s.free_blocks;
  OS.Time.sleep 2. >>
  watchdog ()

let echo () =
  lwt mgr,mgr_t = Manager.create () in
  (* Listen on all interfaces, port 8081 *)
  let src = (None, 8081) in 
  Flow.listen mgr (`TCPv4 (src,
    (fun (remote_addr, remote_port) t ->
       OS.Console.log (sprintf "Connection from %s:%d"
         (Nettypes.ipv4_addr_to_string remote_addr) remote_port);
       let rec echo () =
         lwt res = Flow.read t in
         match res with
         |None ->
            OS.Console.log "Connection closed";
           return ()
         |Some data ->
           Flow.write t data >>
           echo ()
       in
       echo ()
    )
  ))

let _ = OS.Main.run (echo () <&> (watchdog ()))
