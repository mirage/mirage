open Sqlite3
open Printf

let cmd ?(cb=(fun _ _ -> printf "???\n%!")) db sql =
  match exec db sql ~cb with
  | Rc.OK -> ()
  | _ -> failwith (sql ^ " : failed")

let with_time fn =
  let t1 = Mir.gettimeofday () in
  fn ();
  let t2 = Mir.gettimeofday () in
  printf "time: %f\n%!" (t2 -. t1)

let _ =
  try
  let db = db_open "test" in
  print_endline "OPEN done";
  cmd db "CREATE TABLE IF NOT EXISTS foo (a TEXT, b INTEGER, c FLOAT)";
  print_endline "CREATE done";
  cmd db "DELETE FROM foo";
  print_endline "DELETE done";
  let i = 2 in
  cmd db (sprintf "INSERT INTO foo VALUES(\"hello%d\", %d+1, %d.%d)" i i i i);
  let i = 3 in
  cmd db (sprintf "INSERT INTO foo VALUES(\"hello%d\", %d+1, %d.%d)" i i i i);
  let cnt = ref 0 in
  let cb row header = incr cnt in
  cmd ~cb db "SELECT * from foo";
  printf "count=%d\n%!" !cnt;
  assert(!cnt = 2);
  with 
  x -> print_endline ( Printexc.to_string x)
