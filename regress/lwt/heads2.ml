open Lwt (* provides >>= and join *)
open OS  (* provides Time, Console and Main *)

let main () =
  join [
    (Time.sleep 1.0 >>= fun () -> (Console.log "Heads"; return ()));
    (Time.sleep 2.0 >>= fun () -> (Console.log "Tails"; return ()))
  ] >>= fun () ->
    Console.log "Finished";
    return ()
