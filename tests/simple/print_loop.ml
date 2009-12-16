let _ =
  let t1 = Mir.gettimeofday () in
  for i = 0 to 100000000 do
    let _ = String.create 10000 in
    ()
  done;
  let t2 = Mir.gettimeofday () in
  Printf.printf "game over: %.3fs\n%!" (t2 -. t1)
