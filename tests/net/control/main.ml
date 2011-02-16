open Printf
open Lwt

let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  let luid = Net.Manager.local_uid () in
  let rec ping () =
    let peer_uids = Net.Manager.local_peers () in
    Lwt_list.iter_p (fun uid ->
      Net.Manager.ping_peer mgr uid >>= function
        |true -> return (printf "Ping OK : %d -> %d\n%!" luid uid)
        |false -> return (printf "Ping ERR: %d -> %d\n%!" luid uid)
    ) peer_uids >> OS.Time.sleep 1. >>= ping
  in ping ()

let _ = OS.Main.run (main ())
