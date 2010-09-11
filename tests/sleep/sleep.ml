module OS = Browser

open Lwt

let main () =
  OS.Console.log "start";
  for_lwt i = 1 to 10 do
    OS.Console.log (Printf.sprintf "iteration: %d" i);
    OS.Time.sleep ((float_of_int i) );
  done >>
  return (OS.Console.log "done")

let _ = 
  OS.Main.run (main ())
