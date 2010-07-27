open Lwt 

let main () =
    let xsh = Xs.make_mmap () in
    lwt vifs = Netfront.enumerate xsh in
    lwt nfs = Lwt_list.map_s (Netfront.create xsh) vifs in
    Lwt_mirage.sleep 20.

let _ = Lwt_mirage_main.run (main ())
