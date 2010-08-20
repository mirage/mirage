open Lwt 
open Printf
open Xen

let main () =
    lwt vifs = Netfront.enumerate () in
    Lwt_list.iter_s (fun vif_id ->
       Mlnet.Netif.create_dhcp vif_id >>
       Time.sleep 20.
    ) vifs

let _ = Main.run (main ())
