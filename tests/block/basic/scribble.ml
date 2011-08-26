open Lwt
open Printf

let i = ref 0

(* Copy over this page with grafitti *)
let scribble_over_string (s, off, length) =
  let off = off / 8 and length = length / 8 in (* assume byte alignment *)
  let dstoff = ref 0 in
  begin
    try
      while !dstoff < length do
        let msg = Printf.sprintf "%d," !i in
        let len = min (String.length msg) (length - !dstoff) in
        String.blit msg 0 s (off + !dstoff) len;
        dstoff := !dstoff + len;
        incr i;
      done;
    with _ -> ()
  end

let main () =
  lwt ids = OS.Blkif.enumerate () in
  printf "VM has %d block devices configured\n%!" (List.length ids);
  let id = List.hd ids in
  lwt vbd,vbd_t = OS.Blkif.create id in
  printf "Connected block device\n%!";
  lwt bs = OS.Blkif.read_page vbd 0L in
  printf "Read page at offset 0\n%!";
  scribble_over_string bs;
  lwt (_: unit) = OS.Blkif.write_page vbd 0L bs in
  printf "Written page at offset 0\n%!";
  OS.Time.sleep 5.

let _ = OS.Main.run (main ())
