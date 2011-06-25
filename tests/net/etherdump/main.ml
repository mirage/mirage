open Lwt
open Printf
open Net.Nettypes

let input_arp frame bits =
  let open Net.Ethif in
  let dmac = ethernet_mac_to_string frame.dmac in
  let smac = ethernet_mac_to_string frame.smac in
  printf "dmac=%s smac=%s etype=%x\n%!" dmac smac frame.etype;
  return ()
  
let main () =
  match_lwt OS.Netif.enumerate () with
  |[id] -> 
     lwt netif = OS.Netif.create id in
     let ethif, ethif_t = Net.Ethif.create netif in
     Net.Ethif.attach ethif (`ARP input_arp);
     ethif_t
  |_ -> fail (Failure "only 1 netif supported")

let _ = OS.Main.run (main ())
