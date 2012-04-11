open Printf
open Lwt

let with_time i fn =
  let t1 = OS.Clock.time () in
  fn ();
  let t2 = OS.Clock.time () in
  printf "%s %d %.3f\n%!" (Sys.os_type) i (t2 -. t1);
  ()

let main () =
  let rec loop_s =
    function
    |0 -> return ()
    |n -> let t = OS.Time.sleep 0.001 in loop_s (n-1)
  in

  for_lwt i = 1 to 20 do
    let sz = i * 100000 in
    Gc.compact ();
    with_time sz (fun () -> 
      let _ = loop_s sz in ()
    );
    OS.Time.sleep 0.01
  done >>
  OS.Time.sleep 1.
