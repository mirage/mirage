let _ = 
  for y = 1 to 3 do
  for i = 0 to 10 do
    Printf.printf "%d %d\n%!" y i
  done;
  done;
  for i = 0 to 10 do
    Printf.printf "%f\n%!" (float_of_int i)
  done
