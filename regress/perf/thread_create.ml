open Printf
open Lwt

let with_time i label fn =
  let t1 = OS.Clock.time () in
  fn ();
  let t2 = OS.Clock.time () in
  printf "%s,%d,%d,%.3f\n%!" Sys.os_type i label (t2 -. t1)

let main () =
  let sizes = [ 10000; 50000; 100000; 200000; 300000; 400000; 500000 ] in
  let rec loop_s =
    function
    |0 -> return ()
    |n -> let t = OS.Time.sleep 1. in loop_s (n-1)
  in

  List.iter (fun sz ->
    Gc.compact ();
    with_time sz sz (fun () -> 
      let _ = loop_s sz in ()
    )
  ) sizes;
  OS.Time.sleep 1.
