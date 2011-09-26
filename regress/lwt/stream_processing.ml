open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)


let map f source =
  let (s, push) = Lwt_stream.create () in
  let rec aux () = match_lwt Lwt_stream.get source with
    | None -> push None; return ()
    | Some x -> lwt y = f x in push (Some y); aux ()
  in
  let _ = aux () in
  s

let split source =
  let (s1, push1) = Lwt_stream.create () in
  let (s2, push2) = Lwt_stream.create () in
  let rec aux () = match_lwt Lwt_stream.get source with
    | None -> push1 None; push2 None; return ()
    | Some (x,y) -> push1 (Some x); push2 (Some y); aux ()
  in
  let _ = aux () in
  (s1, s2)

let filter f source =
  let (s, push) = Lwt_stream.create () in
  let rec aux () = match_lwt Lwt_stream.get source with
    | None -> push None; return ()
    | Some x -> match_lwt f x with
      | true -> push (Some x); aux ()
      | false -> aux ()
  in
  let _ = aux () in
  s

let add_mult (a, b) =
  return (a + b, a * b) 

let print_and_go str a =
  Console.log (Printf.sprintf "%s %d" str a);
  return a

let test_odd a =
  return (1 = (a mod 2))

let rec print_odd s = 
  match_lwt Lwt_stream.get s with
  | Some a -> Console.log (Printf.sprintf "Odd: %d" a); print_odd s
  | None -> return ()

let ( |> ) x f = f x

let int_server () =
  let (input, push) = Lwt_stream.create () in
  let (sa, sm) = input |> map add_mult |> split in
  let _ = sa |> map (print_and_go "Add:" ) |> filter test_odd |> print_odd in
  let _ = sm |> map (print_and_go "Mult:") |> filter test_odd |> print_odd in
  let rec inp x =
    if x <= 0 then
      return ()
    else begin
      Console.log "----";
      push (Some (Random.int 1000, Random.int 1000));
      Time.sleep 1. >>
      inp (pred x)
    end
  in
  inp 5

let main () =
  Random.self_init ();
  int_server ()

