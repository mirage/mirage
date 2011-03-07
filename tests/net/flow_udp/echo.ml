(* Simple echo server that listens on 8081/UDP
   and sends back everything it reads after a short delay *)

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
  lwt mgr,_ = Manager.create () in
  (* Listen on all interfaces, port 8081 *)
  let port = 8081 in
  let src = (None, port) in 
  Datagram.UDPv4.recv mgr src
    (fun (addr,rport) req ->
(*      let raddr = Nettypes.ipv4_addr_to_string addr in
      OS.Console.log (sprintf "Msg <- %s:%d" raddr rport);
      OS.Console.log (sprintf "Msg -> to %s:%d" raddr (port+1)); *)
      Datagram.UDPv4.send mgr (addr, rport) req
    )
let _ = OS.Main.run (echo () <&> (watchdog ()))
