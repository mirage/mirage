open Lwt
open Printf

let main () =
  OS.Devices.Blkif.manager (fun mgr id blkif ->
    printf "manager: id=%s\n%!" id;
    OS.Time.sleep 5.0 >>
    return (printf "%s done\n%!" id);
  ) >>
  return (printf "should not reach\n%!")

