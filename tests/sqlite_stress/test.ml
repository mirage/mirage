open Sqlite3
open Printf

let iters = 4000

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
  let db = db_open "test" in
  cmd db "CREATE TABLE IF NOT EXISTS foo (a TEXT, b INTEGER, c FLOAT)";
  cmd db "DELETE FROM foo";
  with_time (fun () ->
    for i = 1 to iters do
      cmd db (sprintf "INSERT INTO foo VALUES(\"hello%d\", %d+1, %d.%d)" i i i i)
    done
  );
  let cnt = ref 0 in
  let cb row header = incr cnt in
  cmd ~cb db "SELECT * from foo";
  assert(!cnt = iters);
  printf "count=%d\n%!" !cnt;
  with_time (fun () ->
    for i = 1 to iters do 
      cmd db (sprintf "UPDATE foo SET b=%d WHERE a=\"hello%d\"" (i+1000) i)
    done
  );
  let cnt = ref 0 in
  let cb row header = 
    incr cnt;
    let gr n = match row.(n) with |None -> assert false |Some x -> x in
    let y = int_of_string (gr 1) in
    assert(sprintf "hello%d" (y-1000) = (gr 0))
  in
  cmd ~cb db "SELECT a,b from foo order by b";
  printf "count postupdate=%d\n%!" !cnt
