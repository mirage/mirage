open Lwt (* provides bind and join *)
open OS  (* provides Time, Console and Main *)

let main () =
  bind (join [
    bind (Time.sleep 1.0) (fun () ->
      Console.log "Heads"; return ()
    );
    bind (Time.sleep 2.0) (fun () ->
      Console.log "Tails"; return ()
    );
  ]) (fun () ->
    Console.log "Finished"; return ()
  )

