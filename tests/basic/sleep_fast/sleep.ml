open Lwt
open Printf

let _ =
  OS.Main.run (for_lwt i = 0 to 100000000000 do OS.Time.sleep 0.00001 done)
