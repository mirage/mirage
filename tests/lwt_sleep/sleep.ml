open Printf
open Lwt

let rec mysleep = function
  | 0 -> 
      printf "and all done\n%!"; return ()
  | n -> 
      printf "about to sleep\n%!";
      lwt () = Lwt_mirage.sleep 2.0 in 
      printf "done sleeping\n%!";
      mysleep (n-1)

let _ =
  Lwt_mirage_main.run (mysleep 4)


