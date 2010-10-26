open Lwt
open Http
open Http_daemon

let dispatch conn_id req =
  let body = "<h1>Hello Mirage World</h1>" in
  Http_daemon.respond ~body ()

let exn_handler exn =
  let body = Printexc.to_string exn in
  Printf.printf "exn: %s\n%!" body;
  return ()

let spec = {
  address = "0.0.0.0";
  auth = `None;
  callback = dispatch;
  conn_closed = (fun _ -> ());
  port = 8080;
  exn_handler = exn_handler;
  timeout = Some 300.;
}

let _ = OS.Main.run (main spec)
