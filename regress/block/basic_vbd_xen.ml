open Lwt
open Printf

let main () =
  printf "sleep for 5 seconds\n%!";
  lwt () = OS.Time.sleep 5.0 in
  printf "looking for blkif\n%!";
  let finished_t, u = Lwt.task () in
  let listen_t = OS.Devices.listen (fun id ->
    OS.Devices.find_blkif id >>=
    function
    | None -> return ()
    | Some blkif -> Lwt.wakeup u blkif; return ()
  ) in
  (* Get one device *)
  lwt blkif = finished_t in
  (* Cancel the listening thread *)
  Lwt.cancel listen_t;
  printf "ID: %s\n%!" blkif#id;
  OS.Time.sleep 1.0
