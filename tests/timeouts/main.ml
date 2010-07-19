open Lwt
open Printf

let main () =
   (* Create Lwt_timeout events *)
   let tm n = Lwt_timeout.create n (fun () -> printf "Lwt_timeout %d fired\n%!" n) in
   let tms = List.map tm [1;3;2;5;7;12;15] in
   let ntm = Lwt_timeout.create 20 (fun () -> printf "This timeout should NOT fire\n%!") in
   List.iter Lwt_timeout.start (ntm :: tms);
   (* Create a few Lwt_mirage.timeout to pick too *)
   Lwt_mirage.sleep 30. <?> (Lwt_mirage.sleep 17.)

let _ =
   Lwt_mirage_main.run (main ())
