open Lwt
open Printf

let main () =
  lwt ids = OS.Blkif.enumerate () in
  let id = List.hd ids in
  lwt vbd,vbd_t = OS.Blkif.create id in
  lwt ro = Block.RO.create vbd in
  let files = Hashtbl.fold (fun k v a -> k :: a) ro.Block.RO.files [] in
  Lwt_list.iter_s (fun file ->
    printf "File %s:\n%!" file;
    lwt stream = Block.RO.read ro file in
    Lwt_stream.iter (fun s -> printf "%s%!" (Bitstring.string_of_bitstring s)) stream
  ) files >>
  OS.Time.sleep 5.

let _ = OS.Main.run (main ())
