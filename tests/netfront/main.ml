open Lwt 
open Printf

let main () =
    let xsh = Xs.make_mmap () in
    lwt vifs = Netfront.enumerate xsh in
    lwt nfs = Lwt_list.map_s (
       fun nid ->
         let recv_fn buf = printf "%s\n%!" (Mir.prettyprint buf) in
         Netfront.create xsh nid recv_fn
    ) vifs in
    Lwt_mirage.sleep 20.

let _ = Lwt_mirage_main.run (main ())
