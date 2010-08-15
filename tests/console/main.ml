open Lwt
open Xen

let main () =
   let cons = Console.t in
   let s = "abcdefghi\r\n" in
   Lwt_mirage.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   Lwt_mirage.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   Lwt_mirage.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   return ()
   

let _ = 
   Lwt_mirage_main.run (main ())
