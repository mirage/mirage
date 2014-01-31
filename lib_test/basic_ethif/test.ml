open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Basic (C: V1_LWT.CONSOLE) (S: V1_LWT.STACKV4) = struct

  let start c s =
    S.listen_tcpv4 s ~port:80 (fun flow ->
        let dst, dst_port = S.TCPV4.get_dest flow in
        C.log_s c (green "new tcp connection from %s %d"
                     (Ipaddr.V4.to_string dst) dst_port)
        >>= fun () ->
        S.TCPV4.read flow
        >>= function
        | `Ok b ->
          C.log_s c
            (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
          >>= fun () ->
          S.TCPV4.close flow
        | `Eof -> C.log_s c (red "read: eof")
        | `Error e -> C.log_s c (red "read: error")
      );

      for port = 1 to 200 do
        S.listen_udpv4 s ~port (fun ~src ~dst ~src_port buf ->
            C.log c (blue "udp packet on port %d" port);
            return_unit
          )
      done;

    S.listen s

end
