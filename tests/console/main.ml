open Lwt

let main () =
   let cons = Console.create () in
   let s = "abcdefghi\n" in
   Lwt_mirage.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   Lwt_mirage.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   Lwt_mirage.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   return ()
   

let _ = 
   Lwt_mirage_main.run (main ())
