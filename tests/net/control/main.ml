open Printf
open Lwt

let rec watch () =
  return (printf "watchdog\n%!") >>
  OS.Time.sleep 3. >> 
  watch ()

let talk_to_peers mgr =
  OS.Time.sleep 4. >>
  Lwt_list.iter_p (fun uid ->
    let num = ref 0 in
    Net.Flow.Pipe.connect mgr uid (fun t ->      
      let ch = Net.Channel.Pipe.create t in
      let rec feed () =
        incr num;
        let buf = sprintf "foo %d" !num in
        Net.Channel.Pipe.write_line ch buf >>
        Net.Channel.Pipe.flush ch >>
        return (printf " --> %s\n%!" buf) >>
        lwt line = Net.Channel.Pipe.read_line ch in
        printf "%d <-- %s\n%!" uid line;
        OS.Time.sleep 0.1 >>= feed
      in feed ()
    )
  ) (Net.Manager.local_peers ())

let listen_fn dst t =
    printf "Listen: Connection from UID %d\n%!" dst;
    try_lwt
      let rec echo () =
        let ch = Net.Channel.Pipe.create t in
        lwt line = Net.Channel.Pipe.read_line ch in
        printf "%d <-- %s\n%!" dst line;
        Net.Channel.Pipe.write_line ch (line ^ " XXX") >>
        Net.Channel.Pipe.flush ch >>=
        (printf " --> %s\n%!" line; echo)
      in echo ()
    with exn -> return ()
  
let main () =
  lwt mgr, mgr_t = Net.Manager.create () in
  let listen_t = Net.Flow.Pipe.listen mgr (Net.Manager.local_uid ()) listen_fn in
  let peer_t = talk_to_peers mgr in
  let watch_t = watch () in
  listen_t <&> mgr_t <&> watch_t <&> peer_t

let _ = OS.Main.run (main ())
