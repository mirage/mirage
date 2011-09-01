open Lwt 
open OS

let main () =
  let heads =
    Time.sleep 1.0 >>
    return (Console.log "Heads");
  in
  let tails =
    Time.sleep 2.0 >>
    return (Console.log "Tails");
  in
  lwt () = heads <&> tails in
  Console.log "Finished";
  return ()

