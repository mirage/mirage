(* Stress the Xen grant table code by repeatedly allocating a
   frame, granting it, ending access, and looping *)

open Printf
open OS
open Lwt

let num = ref 0 

let rec watchdog () =
  printf "watchdog: %d\n%!" !num;
  OS.Time.sleep 1.0 >>
  watchdog ()

let rec loop () =
  Gnttab.with_grant ~domid:100 ~perm:Gnttab.RW
    (fun gnt ->
      let _ = Gnttab.page gnt in
      let _ = Gnttab.detach gnt in
      incr num;
      Gc.full_major ();
      Time.sleep 0.001
    )
  >> loop ()

let main () =
  OS.Time.sleep 2.0 
  >> (printf "start\n%!";
      watchdog () <&> (loop ())
  )
