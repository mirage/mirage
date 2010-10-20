open Printf

let with_time i label fn =
  let t1 = OS.Clock.time () in
  fn ();
  let t2 = OS.Clock.time () in
  printf "%s,%d,%d,%.3f\n%!" Sys.os_type i label (t2 -. t1)

let _ =
  (* Gc.set { (Gc.get ()) with Gc.verbose = 0x3 };; *)
  let sizes = [100; 500; 1000; 5000; 10000 ] in
  List.iter (fun sz ->
    with_time sz sz (fun () -> 
      for i = 0 to 100000000 do
        let p = String.create sz in
        ()
      done
    )
  ) sizes
