open V1_LWT
open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Main (C: V1_LWT.CONSOLE) (S: V1_LWT.STACKV4) = struct

  let start console s =

    let module T = S.TCPV4 in
    let module CH = Channel.Make(T) in
    let module H = HTTP.Make(CH) in

    let http_callback conn_id ?body req =
      let path = Uri.path (H.Server.Request.uri req) in
      C.log_s console (Printf.sprintf "Got a request for %s\n" path) >>= fun () ->
      H.Server.respond_string ~status:`OK ~body:"helllp" ()
    in

    let spec = {
      H.Server.callback = http_callback;
      conn_closed = fun _ () -> ();
    } in

    S.listen_tcpv4 s 80 (H.Server.listen spec);
    S.listen s

end
