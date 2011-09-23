(* Simple echo server that listens on 8081 and sends back everything it reads *)

open Lwt
open Printf
open Net
open Nettypes

let addr = ipv4_addr_of_tuple (10l,0l,0l,2l)
let netmask = ipv4_addr_of_tuple (255l,255l,255l,0l)
let gw = [ipv4_addr_of_tuple (10l,0l,0l,1l)]

let echo () =
  printf "start\n%!";
  Manager.create (fun mgr interface id ->
    printf "create %s\n%!" id;
    Manager.configure interface (`IPv4 (addr, netmask, gw)) >>
    let src = (None, 8081) in 
    printf "listen\n%!";
    Channel.listen mgr (
      `TCPv4 (src,
        (fun (remote_addr, remote_port) t ->
           printf "Connection from %s:%d" (Nettypes.ipv4_addr_to_string remote_addr) remote_port;
           let rec echo () =
             try_lwt
               lwt res = Channel.read_crlf t in
               Channel.write_bitstring t res >>
               Channel.write_char t '\n' >>
               Channel.flush t >>
               echo ()
             with Nettypes.Closed -> return ()
           in
           echo () 
        )
      )
    )
  ) >>
  return (printf "done\n%!")
 
let _ = OS.Main.run (echo ())
