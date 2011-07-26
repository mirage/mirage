open Lwt
open Printf

let main () =
  lwt ids = OS.Blkif.enumerate () in
  let id = List.hd ids in
  lwt blkif,blkif_t = OS.Blkif.create id in
  lwt page = OS.Blkif.read_page blkif 0L in
  Bitstring.hexdump_bitstring stdout page;
  OS.Time.sleep 5. <?> blkif_t

let _ = 
  OS.Main.run (main ())
