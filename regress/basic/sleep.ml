open Lwt
open OS

let iter (nm,sz,m) =
  Console.log ("start: " ^ nm);
  let tot = ref 0. in
  for_lwt i = 1 to sz do
    Console.log (Printf.sprintf "%s %d" nm i);
    let t = float_of_int i /. m in
    tot := t +. !tot;
    Time.sleep t;
  done >>
    (Console.log ("done: " ^ nm); return ())

let run () =
  let t1 = "one", 5, 3.1 in
  let t2 = "two", 3, 1.9 in
  let t3 = "three", 4, 1.8 in
  let t4 = "four", 5, 3.2 in
  let r t = iter t >> return () in
  join [r t1; r t2; r t3; r t4]
