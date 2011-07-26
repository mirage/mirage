open Lwt
open Printf
open Net.Nettypes

let addr = match ipv4_addr_of_string "10.0.0.2" with Some x -> x |None -> assert false 

let listen_fn (src_addr, src_port) pcb =
  OS.Time.sleep 5. >>
  return ()

let main () =
  match_lwt OS.Netif.enumerate () with
  |[id] -> 
     lwt netif = OS.Netif.create id in
     let ethif, ethif_t = Net.Ethif.create netif in
     let ipv4 = Net.Ipv4.create ethif in
     let icmp = Net.Icmp.create ipv4 in
     Net.Ipv4.set_ip ipv4 addr >>
     let tcp, tcp_t = Net.Tcp.Pcb.create ipv4 in
     let listen_t = Net.Tcp.Pcb.listen tcp 23 listen_fn in
     ethif_t 
  |_ -> fail (Failure "only 1 netif supported")

let _ = OS.Main.run (main ())
