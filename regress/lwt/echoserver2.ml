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

let read_line () =
  return (String.make (Random.int 20) 'a')

let wait_strlen str =
  OS.Time.sleep (float_of_int (String.length str) /. 10.) >>
  return str

let cap_str str =
  return (String.uppercase str)

let rec print_mvar m =
  lwt s = Lwt_mvar.take m in
  Console.log s;
  print_mvar m

let ( |> ) x f = f x

let echo_server () =
  (*define mailboxes*)
  let m_input = Lwt_mvar.create_empty () in
  let m_output = m_input |> map wait_strlen |> map cap_str in
  (*define loops*)
  let rec read () =
    read_line ()           >>= fun s ->
    Lwt_mvar.put m_input s >>=
    read
  in
  let rec write () =
    Lwt_mvar.take m_output >>= fun r ->
    Console.log r;
    write ()
  in
  (*starts loops*)
  (read ()) <&> (write ())


let main () =
  Random.self_init ();
  let t = echo_server () in
  Time.sleep 5. >>
  (cancel t; return ())
