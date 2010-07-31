open Lwt 
open Printf
open Mlnet
module MT = Mlnet_types

let ip = MT.ipv4_addr_of_tuple (128, 232, 39, 246)
let netmask = MT.ipv4_addr_of_tuple (255, 255, 240, 0)
let gw = MT.ipv4_addr_of_tuple (128, 232, 32, 1)

let main () =
    lwt vifs = Netfront.enumerate () in
    let vif_id = List.hd vifs in
    lwt netif = Netif.create ~ip ~netmask ~gw vif_id in
    Lwt_mirage.sleep 20.

let _ = Lwt_mirage_main.run (main ())
