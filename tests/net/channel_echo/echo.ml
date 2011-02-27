(* Simple echo server that listens on 8081 and sends back everything it reads *)

open Lwt
open Printf
open Net

let echo () =
  lwt mgr,mgr_t = Manager.create () in
  (* Listen on all interfaces, port 8081 *)
  let src = (None, 8081) in 
  Channel.listen mgr (`TCPv4 (src,
    (fun (remote_addr, remote_port) t ->
       OS.Console.log (sprintf "Connection from %s:%d"
         (Nettypes.ipv4_addr_to_string remote_addr) remote_port);
       let rec echo () =
         try_lwt
           let res = Channel.read_crlf t in
           lwt ts = OS.Istring.View.ts_of_stream res in
           let str = OS.Istring.View.ts_to_string ts in
           Channel.write_line t str >>
           Channel.flush t >>
           echo ()
         with Nettypes.Closed -> return ()
       in
       echo () 
    )
  ))

let _ = OS.Main.run (echo ())
