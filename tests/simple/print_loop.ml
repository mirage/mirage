let _ =
  let t1 = OS.Clock.time () in
  for i = 0 to 100000000 do
    let _ = String.create 10000 in
    ()
  done;
  let t2 = OS.Clock.time () in
  Printf.printf "game over: %.3fs\n%!" (t2 -. t1)
