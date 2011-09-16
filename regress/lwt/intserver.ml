open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)

let map f m_in =
  let m_out = Lwt_mvar.create_empty () in
  let rec map_h () =
    Lwt_mvar.take m_in >>=
    f  >>= fun b ->
    Lwt_mvar.put m_out b >>
    map_h () in
  (* t is left unused in this implementation, but should really be
     returned and used to cancel the thread when no longer needed. *)
  let t = map_h () in
  m_out

let split ab =
  let ma = Lwt_mvar.create_empty () in
  let mb = Lwt_mvar.create_empty () in
  let rec split_h () =
    Lwt_mvar.take ab >>= fun (va, vb) ->
    join [Lwt_mvar.put ma va; Lwt_mvar.put mb vb;] >>
    split_h () in
  (* this t is also left unused but shoule be returned *)
  let t = split_h () in  
  (ma, mb)
  
let filter f m_in =
  let m_out = Lwt_mvar.create_empty () in
  let rec filter_h () =
    Lwt_mvar.take m_in >>= fun v ->
    f v                >>= function
    | true -> (Lwt_mvar.put m_out v >>
               filter_h ())
    | false -> filter_h ()
  in
  (* this t is also left unused but shoule be returned *)
  let t = filter_h () in
  m_out

let add_mult (a, b) =
  return (a + b, a * b) 

let print_and_go str a =
  Console.log (Printf.sprintf "%s %d" str a);
  return a

let test_odd a =
  return (1 = (a mod 2))

let rec print_odd m = 
  lwt a = Lwt_mvar.take m in
  Console.log (Printf.sprintf "Odd: %d" a);
  print_odd m

let ( |> ) x f = f x

let int_server () =
  let m_input = Lwt_mvar.create_empty () in
  let (ma, mm) = m_input |> map add_mult |> split in
  let _ = ma |> map (print_and_go "Add:") |> filter test_odd |> print_odd in
  let _ = mm |> map (print_and_go "Mult:") |> filter test_odd |> print_odd in
  let rec inp () =
    Console.log "----";
    Lwt_mvar.put m_input (Random.int 1000, Random.int 1000) >>
    Time.sleep 1. >>
    inp () in
  inp ()

let main () =
  Random.self_init ();
  let t = int_server () in
  Time.sleep 5. >>
  (cancel t; return ())

