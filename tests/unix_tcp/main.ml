module Flow=OS.Flow
open Lwt
open Mlnet.Types

let main () =
(*
  let connect_thread =
    let sa = Flow.TCP (ipv4_localhost, 8080) in
    lwt ic,oc = IO.open_connection sa in
    for_lwt i = 0 to 10 do
     IO.write_line oc ("foo bar " ^ (string_of_int i)) >>
     (print_endline "wrote"; return ())
    done 
  in
*)
  let lsa = TCP (ipv4_localhost, 8081) in
  let listen_t = Flow.listen (fun sa c ->
    let ip,port = match sa with TCP (x,y) -> x,y |_ -> assert false in
    Printf.printf "connection from: %s:%d\n%!" (ipv4_addr_to_string ip) port;
    OS.Time.sleep 5. >>
    let msg = "byebye" in
    lwt _ = Flow.write c msg 0 (String.length msg) in
    return ()
  ) lsa in
  pick [ listen_t; OS.Time.sleep 10. ] >>
  (print_endline "sleep2"; OS.Time.sleep 5.)

let _ = OS.Main.run (main ())

