open Printf
open OS
open Lwt

let num = ref 0 

let rec watchdog () =
  let open Gc in
  Gc.compact ();
  let s = stat () in
  printf "blocks: l=%d f=%d\n%!" s.live_blocks s.free_blocks;
  OS.Time.sleep 2. >>
  watchdog ()

let rec loop () =
  let istr = Istring.Raw.alloc () in
  incr num;
  Gc.compact ();
  Time.sleep 0.001 >> loop ()

let main () =
  (printf "start\n%!";
  watchdog () <&> (loop ()) )

let _ = Main.run (main ())
