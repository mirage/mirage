open Lwt 
open Printf

module OS = Xen
module Eth = Mlnet.Ethif.Ethernet(OS.Netfront.Ethif)
module Arp = Mlnet.Arp.ARP(Eth)
module IPv4 = Mlnet.Ipv4.IPv4(Eth)(Arp)

let main () =
    lwt vifs = Eth.enumerate () in
    let arp_t = List.map (fun id ->
       lwt (t,thread) = IPv4.create_dhcp id in
       thread
    ) vifs in
    pick (OS.Time.sleep 20. :: arp_t) >>
    return (printf "success\n%!")

let _ = OS.Main.run (main ())
