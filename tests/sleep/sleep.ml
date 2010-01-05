let _ =
  let t1 = Mir.gettimeofday () in
  Mir.sleep 10;
  let t2 = Mir.gettimeofday () in
  Printf.printf "slept: %.3fs\n%!" (t2 -. t1)
