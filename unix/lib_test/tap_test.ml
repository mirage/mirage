open Lwt
open Printf

let main () =
  lwt t = OS.Netif.create
    (fun id netif ->
       eprintf "netif open %s\n%!" id;
       lwt () = OS.Time.sleep 1.0 in
       OS.Netif.listen netif 
         (fun page ->
            eprintf "incoming %d\n%!" (Cstruct.len page);
            return ()
         )
    )
  in
  eprintf "netif thread done\n%!";
  return ()

let _ = OS.Main.run (main ())
