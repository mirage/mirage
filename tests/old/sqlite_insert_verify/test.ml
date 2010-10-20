open Sqlite3
open Printf

let cmd ?(cb=(fun _ _ -> printf "???\n%!")) db sql =
  match exec db sql ~cb with
  | Rc.OK -> ()
  | _ -> failwith (sql ^ " : failed")

let with_time i label fn =
  let t1 = Mir.gettimeofday () in
  fn ();
  let t2 = Mir.gettimeofday () in
  printf "%s,%d,%s,%f\n%!" Sys.os_type i label (t2 -. t1)

let with_trans db fn =
  cmd db "begin";
  fn db;
  cmd db "end"

let delete_all db =
  cmd db "DELETE from foo"

let insert_mass iters db =
  for i = 1 to iters do
    cmd db (sprintf "INSERT INTO foo VALUES(\"hello%d\", %d+1, %d.%d)" i i i i)
  done

let insert_large_mass sz iters db =
  for i = 1 to iters do
    cmd db (sprintf "INSERT INTO foo VALUES(\"%s%d\", %d+1, %d.%d)" (String.make sz 'x') i i i i);
  done

let select_check sz db =
  let cnt = ref 0 in
  let cb _ _ = incr cnt in
  cmd ~cb db "SELECT * from foo";
  if !cnt != sz then failwith (sprintf "cnt %d != sz %d" !cnt sz)

let update_mass iters db =
  for i = 1 to iters do 
    cmd db (sprintf "UPDATE foo SET b=%d WHERE c=%d.%d" (i+1000) i i)
  done

let check_update db =
  let cnt = ref 0 in
  let cb row header = 
    incr cnt;
    let gr n = match row.(n) with |None -> assert false |Some x -> x in
    let y = int_of_string (gr 1) - 1000 in
    let s = sprintf "%s%d" (String.make 8192 'x') y in
    assert(s = (gr 0))
  in
  cmd ~cb db "SELECT a,b from foo";
  printf "verified\n%!"

let ins_up_del insertfn iters db =
  select_check 0 db;
  insertfn iters db;
  select_check iters db;
  update_mass iters db;
  select_check iters db

let _ =
  try
    let db = db_open "test" in
    check_update db
    
  with e -> (print_endline (Printexc.to_string e); raise e)
