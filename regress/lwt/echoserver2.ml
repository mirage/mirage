open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)
open Lwt_mvar


let map f a =
  let m = Lwt_mvar.create_empty () in
  let rec map_h () =
    Lwt_mvar.take a >>=
    f  >>=
    fun b -> Lwt_mvar.put m b >>=
    fun () -> map_h () in
  let t = map_h () in
  m
  

let split ab =
  let ma = Lwt_mvar.create_empty () in
  let mb = Lwt_mvar.create_empty () in
  let rec split_h () =
    Lwt_mvar.take ab >>=
      fun (va, vb) ->
	join [Lwt_mvar.put ma va; Lwt_mvar.put mb vb;] >>=
	fun _ -> split_h () in
  let t = split_h () in
  (ma, mb)
  

let filter f a =
  let m = Lwt_mvar.create_empty () in
  let rec filter_h () = Lwt_mvar.take a >>=
    fun v -> f v >>=
    fun w -> match w with
               | true -> (Lwt_mvar.put m v >>=
	                  fun _ -> filter_h ())
	     | false -> filter_h () in
  let t = filter_h () in
  m


let read_line () =
  return (String.make (Random.int 20) 'a')


let wait_strlen str =
  OS.Time.sleep (float_of_int (String.length str))>>=
  fun () ->
    return str


let cap_str str =
  return (String.uppercase str)


let rec print_mvar m =
  Lwt_mvar.take m >>=
  fun s ->
    Console.log s;
    print_mvar m


let echo_server () =
  let m = create_empty () in
  let m_delayed = map wait_strlen m in
  let m_cap = map cap_str m_delayed in
  let _ = print_mvar m_cap in
  let rec one_line n = 
    read_line () >>=
    fun s ->
      let str = Printf.sprintf "%d: %s" n s in
        Console.log str;
        Lwt_mvar.put m str >>
        one_line (n + 1) in
  one_line 1


let main () =
  Random.self_init ();
  echo_server ()

