open Lwt

let p x = print_endline x; Gc.compact ()

let xs_test () =
   p "starting";
   let con = Xsraw.open_mmap () in
   let try_xs fn =
      try_lwt fn con 
      with 
      |  Xs_packet.Error e -> return (Printf.sprintf "ERROR(%s)" e)
      |  Xb.Noent -> return "NOENT"
   in
   let try_xs_unit fn =
      try_lwt fn con 
      with _ -> return ()
   in
   p "read /vm";
   lwt vm = try_xs (Xsraw.read 0 "vm") in
   p ("/vm: " ^ vm);

   let vif n = try_xs (Xsraw.read 0 (Printf.sprintf "device/vif/%d/backend-id" n)) in
   lwt vif0 = vif 0 in
   p ("vif0: " ^ vif0);

   Xsraw.write 0 "device/vif/0/foo" "bar" con >> 
   lwt viffoo0 = try_xs (Xsraw.read 0 "device/vif/0/foo") in
   p (Printf.sprintf "vif0 write: %s" vif0 viffoo0);
   
   lwt ()  = Lwt_mirage.sleep 10. in
   p "done";
   return ()

let _ =
   Lwt_mirage.run (xs_test ())
