(* Test to check that low-level tuntap transmit/receive
   is working *)

open Lwt
open Printf

let main () =
  printf "OS.Ethif.create\n%!"; 
  lwt ids = OS.Ethif.enumerate () in
  let id = List.hd ids in
  lwt netif,listen_t = Mlnet.Ethif.create id in
  lwt () = listen_t in
  return (printf "Done\n%!")

let _ = OS.Main.run (main ())
