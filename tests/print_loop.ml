open Pervasives

let main arg =
  for i = 0 to 1000000 do
    let _ = String.create 10000 in
    if i mod 10000 = 0 then print_endline (string_of_int i)
  done;
  print_endline "game over"

let _ = Callback.register "main" main
