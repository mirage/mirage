open Lwt 
open Printf

let main () =
    let xsh = Xs.make_mmap () in
    lwt vifs = Netfront.enumerate xsh in
    lwt nfs = Lwt_list.map_s (
       fun nid ->
         lwt nf = Netfront.create xsh nid in
         Netfront.set_recv nf (fun buf -> 
            Ethernet.recv nf buf >>
            Lwt_mirage.sleep 2. >>
            return (printf "%s: slept\n%!" (Netfront.mac nf))
         );
         return nf
    ) vifs in
    Lwt_mirage.sleep 20.

let _ = Lwt_mirage_main.run (main ())
