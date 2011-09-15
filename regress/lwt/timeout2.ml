open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)

let timeout f t =
  let tmout = Time.sleep f in
  pick [
    (tmout >>= fun () -> return None);
    (t >>= fun v -> return (Some v));
  ]

let main () =
  Random.self_init ();
  let t =
    Time.sleep (Random.float 6.0) >>= fun () ->
    return "Heads"
  in
  timeout 4.0 t >>= fun v ->
  match v with
  | Some s -> Console.log (Printf.sprintf "Some %s" s); return ()
  | None   -> Console.log (Printf.sprintf "None"); return ()


