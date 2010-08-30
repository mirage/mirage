open Lwt 
open Printf
open Mlnet.Mlnet_types
module OS = Unix
module Eth = Mlnet.Ethif.Ethernet(OS.Ethif)
module Arp = Mlnet.Arp.ARP(Eth)
module IPv4 = Mlnet.Ipv4.IPv4(Eth)(Arp)
module ICMP = Mlnet.Icmp.ICMP(IPv4)

let ip = match ipv4_addr_of_string "10.0.0.2" with Some x -> x |None -> assert false
let nm = match ipv4_addr_of_string "255.255.255.0" with Some x -> x |None -> assert false
 
let main () =
    lwt vifs = Eth.enumerate () in
    let arp_t = List.map (fun id ->
       lwt (t,thread) = IPv4.create id in
       IPv4.set_ip t ip >>
       IPv4.set_netmask t nm >>
       let _ = ICMP.create t in
       thread
    ) vifs in
    pick (OS.Time.sleep 40. :: arp_t) >>
    return (printf "success\n%!")

let _ = OS.Main.run (main ())
