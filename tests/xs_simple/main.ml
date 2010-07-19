open Lwt
open Printf

let p x = print_endline x; Gc.compact ()

let xs_test () =
   p "starting";
   let xsh = Xs.make_mmap () in
   let try_xs fn a =
      try_lwt fn a
      with 
      |  Xs_packet.Error e -> return (sprintf "ERROR(%s)" e)
      |  Xb.Noent -> return "NOENT"
   in
   let try_xs_unit fn a =
      try_lwt fn a
      with _ -> return ()
   in
   p "read /vm";
   lwt vm = try_xs xsh.Xs.read "vm" in
   p ("/vm: " ^ vm);

   let vif n = try_xs xsh.Xs.read (sprintf "device/vif/%d/backend-id" n) in
   lwt vif0 = vif 0 in
   p ("vif0: " ^ vif0);

   try_xs_unit (xsh.Xs.write "device/vif/0/foo") "bar" >> 
   lwt viffoo0 = try_xs xsh.Xs.read "device/vif/0/foo" in
   p (sprintf "vif0 write: %s" viffoo0);

   let watchpath = "device/vif" in
   let timeout = 10. in
   p ("sleeping to watch " ^ watchpath ^ " for " ^ (string_of_float timeout));
   try_lwt
       Xs.monitor_paths xsh [ watchpath, "XXX" ] timeout
           (fun (k,v) -> printf "watch callback: [ %s = %s ]\n%!" k v; false)
   with
       Xs.Timeout -> begin
           print_endline "timed out";
           return ()
       end
         

let _ =
   Lwt_mirage.run (xs_test ())
