open Lwt
open Printf

let main () =
  let k = "/tmp/bar2" in
  let v = "hello world" in
  lwt () = OS.Console.log_s (sprintf "hello world! writing to %s\n" k) in
  lwt domid = OS.Xs.(t.read "domid") >|= int_of_string in
  OS.Console.log (sprintf "my domid is %d\n" domid);
  OS.Xs.(transaction t (fun xst ->
    let open OS.Xst in
    lwt () = xst.write k v in
    xst.setperms k (domid, OS.Xsraw.PERM_RDWR, [domid+1, OS.Xsraw.PERM_WRITE])
  ))
