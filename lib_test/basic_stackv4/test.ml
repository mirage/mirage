open V1_LWT
open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Handler (C: V1_LWT.CONSOLE) (S: V1_LWT.STACKV4) = struct

    module T = S.TCPV4
    module CH = Channel.Make(T)
    module H = HTTP.Make(CH)

    let start console s =

      let http_callback conn_id ?body req =
        let path = Uri.path (H.Server.Request.uri req) in
        C.log_s console (Printf.sprintf "Got a request for %s\n" path) >>= fun () ->
        H.Server.respond_string ~status:`OK ~body:"helllp" ()
      in

      let spec = {
        H.Server.callback = http_callback;
        conn_closed = fun _ () -> ();
      } in

      S.listen_udpv4 s 53 (
        fun ~src ~dst ~src_port buf ->
          C.log_s console "got udp on 53"
      );
      S.listen_tcpv4 s 80 (
        fun flow ->
          let dst, dst_port = T.get_dest flow in
          C.log_s console
            (green "new tcp connection from %s %d" (Ipaddr.V4.to_string dst) dst_port)
          >>= fun () ->
          T.read flow
          >>= function
          | `Ok b ->
            C.log_s console
              (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
            >>= fun () ->
            T.close flow
          | `Eof -> C.log_s console (red "read: eof")
          | `Error e -> C.log_s console (red "read: error")
      );
      S.listen_tcpv4 s 8080 (H.Server.listen spec);
      S.listen s

end
