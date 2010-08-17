open Lwt 
open Printf
open Xen

let main () =
    lwt vifs = Netfront.enumerate () in
    Lwt_list.iter_s (fun vif_id ->
       lwt (netif,recv_t) = Mlnet.Netif.create_dhcp vif_id in
       Time.sleep 20.
    ) vifs

let _ = Main.run (main ())
