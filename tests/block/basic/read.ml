open Lwt
open Printf

let main () =
  Block.Manager.create (fun mgr vbd id ->
    printf "Block.Manager: plug %s\n%!" id;
    lwt ro = Block.RO.create vbd in
    Block.RO.iter_s ro (fun file ->
      printf "File %s:\n%!" file;
      lwt stream = Block.RO.read ro file in
      Lwt_stream.iter (fun s -> printf "%s%!" (Bitstring.string_of_bitstring s)) stream
    ) >>
    OS.Time.sleep 5.
   )

let _ = OS.Main.run (main ())
