open Printf

let with_time i label fn =
  let t1 = Mir.gettimeofday () in
  fn ();
  let t2 = Mir.gettimeofday () in
  printf "%s,%d,%d,%.3f\n%!" Sys.os_type i label (t2 -. t1)

let _ =
  Gc.set { (Gc.get ()) with Gc.verbose = 0x01 };;
  let sizes = [1000; ] in
  List.iter (fun sz ->
    with_time sz sz (fun () -> 
      for i = 0 to 100000 do
        let _ = String.create sz in
        ()
      done;
    )
  ) sizes
