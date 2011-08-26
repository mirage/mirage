open Lwt
open Printf

let main () =
  lwt ids = OS.Blkif.enumerate () in
  printf "VM has %d block devices configured\n%!" (List.length ids);
  let id = List.hd ids in
  lwt vbd,vbd_t = OS.Blkif.create id in
  printf "Connected block device\n%!";
  lwt bs = OS.Blkif.read_page vbd 0L in
  let s, _, _ = bs in
  printf "Read page at offset 0\n%!";
  (* Copy over this page with grafitti *)
  let msg = "hello there\n" in
  let dstoff = ref 0 in
  begin
    try
      while true do
        String.blit msg 0 s !dstoff (String.length msg);
         dstoff := !dstoff + (String.length msg);
      done;
    with _ -> ()
  end;
  lwt (_: unit) = OS.Blkif.write_page vbd 0L bs in
  printf "Written page at offset 0\n%!";
  OS.Time.sleep 5.

let _ = OS.Main.run (main ())
