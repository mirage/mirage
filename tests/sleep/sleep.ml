module OS = Browser

open Lwt

let iter (nm,sz,m) =
  OS.Console.log ("start: " ^ nm);
  let tot = ref 0. in
  for_lwt i = 1 to sz do
    OS.Console.log (Printf.sprintf "iteration: %s %d" nm i);
    let t = float_of_int i /. m in
    tot := t +. !tot;
    OS.Time.sleep t;
  done >>
  (OS.Console.log ("done: " ^ nm); return !tot)

let main () =
  let t1 = "one", 10, 2. in
  let t2 = "two", 6, 1.9 in
  let t3 = "three", 8, 1.8 in
  let t4 = "four", 8, 1.2 in
  let r t = iter t >> return () in
  join [r t1; r t2; r t3; r t4] >>
  return ()

let _ = 
  OS.Main.run (main ())
