(* Simple echo server that listens on 8081/UDP
   and sends back everything it reads after a short delay *)

open Lwt
open Printf
open Net

module F = Flow.UDPv4

let echo () =
  lwt mgr = Manager.create () in
  (* Listen on all interfaces, port 8081 *)
  let port = 8081 in
  let src = (None, port) in 
  F.recv mgr src
    (fun (addr,rport) req ->
      let raddr = Nettypes.ipv4_addr_to_string addr in
      OS.Console.log (sprintf "Msg <- %s:%d" raddr rport);
      lwt () = OS.Time.sleep 3. in
      OS.Console.log (sprintf "Msg -> to %s:%d" raddr (port+1));
      F.send mgr (addr, port+1) req
    )
let _ = OS.Main.run (echo ())
