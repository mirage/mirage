open Printf
open Lwt

let tm = Mir.gettimeofday

let rec mysleep = function
  | 0 -> 
      printf "and all done\n%!"; return ()
  | n -> 
      printf "about to sleep: \n%!";
      let t1 = tm () in
      lwt () = Lwt_mirage.sleep (float_of_int (n * 2)) in 
      let t2 = tm () in
      printf "done sleeping: %f\n%!" (t2 -. t1);
      mysleep (n-1)

let _ =
  Lwt_mirage_main.run (mysleep 4)


