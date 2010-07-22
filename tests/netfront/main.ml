open Lwt 

let main () =
    let xsh = Xs.make_mmap () in
    Gnttab.init ();
    lwt vifs = Netfront.enumerate xsh in
    lwt nfs = Lwt_list.map_s (Netfront.create xsh) vifs in
    return ()

let _ = Lwt_mirage_main.run (main ())
