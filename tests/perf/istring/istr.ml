open Printf
open OS
open Lwt

let num = ref 0 

let rec watchdog () =
  printf "watchdog: %f %d\n%!" (OS.Clock.time ()) !num;
  OS.Time.sleep 1.0 >>
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
