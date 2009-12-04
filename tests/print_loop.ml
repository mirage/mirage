open Pervasives

let _ =
  for i = 0 to 50 do
    print_endline ("hello world " ^ (string_of_int i))
  done;
  print_endline "game over"
