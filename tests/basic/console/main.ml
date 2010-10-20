open Lwt
open OS

let main () =
   let cons = Console.t in
   let s = "abcdefghi\r\n" in
   Time.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   Time.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   Time.sleep 4. >>
   Console.sync_write cons s 0 (String.length s) >>
   return ()

let _ = Main.run (main ())
