open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)

let map f m_in =
  let m_out = Lwt_mvar.create_empty () in
  let rec map_h () =
    Lwt_mvar.take m_in >>=
    f >>=
    fun v -> Lwt_mvar.put m_out v >>=
    fun () -> map_h () in
  let t = map_h () in
  m_out
 
let split mab =
  let ma = Lwt_mvar.create_empty () in
  let mb = Lwt_mvar.create_empty () in
  let rec split_h () =
    Lwt_mvar.take mab >>=
      fun (va, vb) ->
        join [
          Lwt_mvar.put ma va;
          Lwt_mvar.put mb vb;
        ] >>=
      fun () -> split_h () in
  let t = split_h () in
  (ma, mb)
 
let filter f a =
  let m = Lwt_mvar.create_empty () in
  let rec filter_h () = Lwt_mvar.take a >>=
    fun v -> f v >>=
    fun w -> match w with
             | true -> (Lwt_mvar.put m v >>=
                        fun () -> filter_h ())
             | false -> filter_h () in
  let t = filter_h () in
  m

let add_mult (a, b) =
  return (a + b, a * b) 

let print_and_go str a =
  Console.log (Printf.sprintf "%s %d" str a);
  return a

let test_odd a =
  return (1 == (a mod 2))

let rec print_odd m = 
  lwt a = Lwt_mvar.take m in
  Console.log (Printf.sprintf "Odd: %d" a);
  print_odd m

let main () =
  Random.self_init ();
  let m_input = Lwt_mvar.create_empty () in
  let m_add_mult = map add_mult m_input in
  let (ma, mm) = split m_add_mult in
  let ma_p = map (print_and_go "Add:") ma in
  let ma_p_f = filter test_odd ma_p in
  let mm_p = map (print_and_go "Mult:") mm in
  let mm_p_f = filter test_odd mm_p in
  let rec inp () = (* XXX test never terminates *)
    Console.log "----";
    Lwt_mvar.put m_input (Random.int 1000, Random.int 1000) >>
    Time.sleep 1. >>
    inp () in
  let _ = print_odd ma_p_f in
  let _ = print_odd mm_p_f in
  inp ()
