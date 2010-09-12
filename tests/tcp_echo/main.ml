module OS = Unix
module Eth = Mlnet.Ethif.Ethernet(OS.Ethif)
module Arp = Mlnet.Arp.ARP(Eth)
module IPv4 = Mlnet.Ipv4.IPv4(Eth)(Arp)
module ICMP = Mlnet.Icmp.ICMP(IPv4)
module UDP = Mlnet.Udp.UDP(IPv4)
module TCP = Mlnet.Tcp.TCP(IPv4)
module DHCP = Mlnet.Dhcp.Client(IPv4)(UDP)(OS.Time)

open Lwt 
open Printf
open Mlnet.Mlnet_types

let ipaddr = match ipv4_addr_of_string "10.0.0.2" with Some x -> x |None -> assert false
let nm = match ipv4_addr_of_string "255.255.255.0" with Some x -> x |None -> assert false

let use_dhcp = false

let main () =
    lwt vifs = Eth.enumerate () in
    let vif_t = List.map (fun id ->
       lwt (ip,ip_t) = IPv4.create id in
       let (icmp,icmp_t) = ICMP.create ip in
       let (udp,udp_t) = UDP.create ip in
       let ipaddr_t = (match use_dhcp with
        | true -> 
            lwt (dhcp,dhcp_t) = DHCP.create ip udp in
            dhcp_t
        | false ->
            IPv4.set_netmask ip nm >>
            IPv4.set_ip ip ipaddr >>
            return ()
       ) in
       let (tcp,tcp_t) = TCP.create ip in
       TCP.listen tcp 23 (fun ip tcp ->
         print_endline "TCP: listen 23 input received";
         Mpl.Tcp.prettyprint tcp;
         return ()
       );
       join [ ip_t; icmp_t; udp_t; ipaddr_t; tcp_t ]
    ) vifs in
    pick (OS.Time.sleep 120. :: vif_t) >>
    return (printf "success\n%!")

let _ = OS.Main.run (main ())
