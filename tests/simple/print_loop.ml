open Pervasives

let tm = Sys.time

let main () =
  let t1 = tm () in
  for i = 0 to 10000000 do
    let _ = String.create 10000 in
    if i mod 50000 = 0 then
      Printf.printf "%d\n%!" i
  done;
  let t2 = tm () in
  let t = int_of_float ( (t2 -. t1) *. 100. ) in
  Printf.printf "game over: %d\n%!" t

let _ = main ()
