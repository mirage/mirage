open Lwt
open Printf

let p x = OS.Console.log x; Gc.compact ()

let xs_test () =
   p "starting";
   let xsh = OS.Xs.t in
   let try_xs fn a =
      try_lwt
        fn a
      with 
      |OS.Xs_packet.Error e -> return (sprintf "ERROR(%s)" e)
      |OS.Xb.Noent -> return "NOENT"
   in
   let try_xs_unit fn a =
    try_lwt fn a
    with _ -> return ()
   in
   p "read /vm";
   lwt vm = try_xs xsh.OS.Xs.read "vm" in
   p ("/vm: " ^ vm);

   let vif n = try_xs xsh.OS.Xs.read (sprintf "device/vif/%d/backend-id" n) in
   lwt vif0 = vif 0 in
   p ("vif0: " ^ vif0);

   try_xs_unit (xsh.OS.Xs.write "device/vif/0/foo") "bar" >> 
   lwt viffoo0 = try_xs xsh.OS.Xs.read "device/vif/0/foo" in
   p (sprintf "vif0 write: %s" viffoo0);

   let watchpath = "device/vif" in
   let timeout = 9.5 in
   p ("sleeping to watch " ^ watchpath ^ " for " ^ (string_of_float timeout));
   try_lwt
       OS.Xs.monitor_paths xsh [ watchpath, "XXX" ] timeout
           (fun (k,v) ->
               printf "watch callback: [ %s = %s ]\n%!" k v;
               match k with
               | "device/vif/foo" -> true
               | _ -> false)
   with
       OS.Xs.Timeout -> begin
           OS.Console.log "timed out";
           return ()
       end
         

let _ =
   OS.Main.run (xs_test ())
