open Lwt 
open Printf

(* 
module OS = Unix
module Eth = Mlnet.Ethif.Ethernet(OS.Ethif)
module Arp = Mlnet.Arp.ARP(Eth)
module IPv4 = Mlnet.Ipv4.IPv4(Eth)(Arp)
module ICMP = Mlnet.Icmp.ICMP(IPv4)
module UDP = Mlnet.Udp.UDP(IPv4)
module DHCP = Mlnet.Dhcp.Client(IPv4)(UDP)(OS.Time)
*)

module Eth = Mletherip.Ethif.T(OS.Ethif)
module Arp = Mletherip.Arp.T(Eth)
module IPv4 = Mletherip.Ipv4.T(Eth)(Arp)
module ICMP = Mletherip.Icmp.T(IPv4)
module UDP = Mludp.Udp.Socket(IPv4)
module TCP = Mltcp.Tcp.Server(IPv4)
module DHCP = Mldhcp.Client.T(IPv4)(UDP)(OS.Time)


let string_of_id i = return (sprintf "%s" i)

let main () =
  lwt vifs = Eth.enumerate () in
  let _ = map (fun i -> printf "%s" (string_of_id i)) vifs in
  let vif_t = List.map (fun id ->
       lwt (ip,thread) = IPv4.create id in
(*       let icmp,icmp_t = ICMP.create ip in *)
       let udp,udp_t = UDP.create ip in
       lwt () = OS.Time.sleep 5. in
       lwt _ = DHCP.create ip udp in
       thread
    ) vifs in
    pick (OS.Time.sleep 120. :: vif_t) >>
    return (printf "success\n%!") in

let _ = OS.Main.run (main ())
