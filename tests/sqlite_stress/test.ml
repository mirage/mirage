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
  printf "%s,%d,%s,%.3f\n%!" Sys.os_type i label (t2 -. t1)

let with_trans db fn =
  cmd db "begin";
  fn db;
  cmd db "end"

(*let with_trans db fn = fn db *)

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
    let y = int_of_string (gr 1) in
    assert(sprintf "hello%d" (y-1000) = (gr 0))
  in
  cmd ~cb db "SELECT a,b from foo order by b"

let ins_up_del insertfn iters db =
  select_check 0 db;
  insertfn iters db;
  select_check iters db;
  update_mass iters db;
  delete_all db;
  select_check 0 db;
  ignore(Gc.stat ())

let sets = [ 1; 10; 50; 100; 200; 500; 1000; 2500; 5000; 7500 ]
let sets = [ 1; 10; 50; 100; 200; 500; 1000; 2500; 5000]
let _ =
  try
    let db = db_open "test" in
    cmd db "CREATE TABLE IF NOT EXISTS foo (a TEXT, b INTEGER, c FLOAT)";
    delete_all db;
(*
    List.iter (fun i ->   
      List.iter (fun sz -> 
        with_time i (sprintf "%d" sz) 
          (fun () -> with_trans db (ins_up_del (insert_large_mass sz) i))) sizes
    ) sets
*)
   let i = 500 in
   let sizes = [ 4; 256; 1024; 2048; 3072; 4096; 6144; 8192 ] in

   
    List.iter (fun sz ->
       with_time i (sprintf "%d" sz)
         (fun () -> ins_up_del (insert_large_mass sz) i db)) sizes
    
  with e -> (print_endline (Printexc.to_string e); raise e)
