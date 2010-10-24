open Lwt
open Printf
open Socket

let listener client flow  =
  printf "listener: start\n%!";
  OS.Time.sleep 5. >>
  Flow.write flow "hello\n" 0 6 >>
  return (printf "listener: end\n%!")

let main () =
  printf "main\n%!";
  let c = Flow.listen listener Nettypes.(TCP (ipv4_localhost,8080)) in
  printf "sleep\n%!";
  (OS.Time.sleep 120. <?> c) >>
  return (printf "done\n%!")

let _ = OS.Main.run (main ())
