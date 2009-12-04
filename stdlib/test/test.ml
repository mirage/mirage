open Pervasives

let foo () = "foo"

let _ = 
  let a = [ 1; 2; 3 ] in
  let r = List.fold_left (fun a b -> a + b) 0 a in
  Printf.printf "res: %d\n%!" r;
  ()
