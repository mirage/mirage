module OS=Unix
module Channel=OS.Channel
module IO=Io.Channel.IO(OS.Channel)
open Lwt
open Mlnet.Types

let main () =
  let sa = Channel.TCP (ipv4_localhost, 8080) in
  lwt ic,oc = IO.open_connection sa in
  try_lwt
  for_lwt i = 0 to 10 do
    IO.write_line oc ("foo bar " ^ (string_of_int i)) >>
    (print_endline "wrote"; return ())
  done >>
 ( print_endline "about to sleep";
  OS.Time.sleep 120.)
  with Lwt.Canceled ->
    print_endline "cancelled!"; return ()

let _ = OS.Main.run (main ())

