open Printf
open Lwt

let with_time i label fn =
  let t1 = OS.Clock.time () in
  fn ();
  let t2 = OS.Clock.time () in
  printf "%s,%d,%d,%.3f\n%!" Sys.os_type i label (t2 -. t1)

let main () =
  let sizes = [1; 500; 2500; 5000; 10000; 15000; 30000; 50000; 100000; 250000 ] in
  let sizes = [1; 500; 2500; 5000; 10000; 15000; ] in
  List.iter (fun sz ->
    with_time sz sz (fun () -> 
      for i = 0 to 1000000 do
        let _ = String.create sz in
        ()
      done;
    )
  ) sizes;
  return ()
