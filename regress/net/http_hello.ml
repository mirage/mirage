(* Simple hello world webserver *)

open Printf
open Lwt

let auth = `None

let conn_closed id =
  ()

let port = 80

let callback id req =
  Http.Server.respond ~body:"hello mirage world"
    ~headers:["x-foo","bar"] () 

let exn_handler exn =
  printf "exn: %s\n%!" (Printexc.to_string exn);
  return ()

let spec = {
  Http.Server.address="foo";
  auth = `None;
  callback;
  conn_closed;
  port;
  exn_handler;
  timeout= None
}


let ip = Net.Nettypes.(
  (ipv4_addr_of_tuple (10l,0l,0l,2l),
   ipv4_addr_of_tuple (255l,255l,255l,0l),
   [ ipv4_addr_of_tuple (10l,0l,0l,2l) ]
  ))

let print_data =
  while_lwt true do
  Printf.printf ">>>>>>>>>>>>>>>> live_words = %d\n%!" Gc.((stat()).live_words);
  OS.Time.sleep 3.0
 done
  

let main () =
  Log.info "Echo" "starting server";
  Net.Manager.create (fun mgr interface id ->
    Net.Manager.configure interface (`IPv4 ip);
    Http.Server.listen mgr (`TCPv4 ((None, port), spec))
  )


