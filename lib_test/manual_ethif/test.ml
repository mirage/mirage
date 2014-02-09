open V1_LWT
open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Basic (C: CONSOLE) (N: NETWORK) = struct

  module E = Ethif.Make(N)
  module I = Ipv4.Make(E)
  module U = Udpv4.Make(I)
  module T = Tcpv4.Flow.Make(I)(OS.Time)(Clock)(Random)
  module D = Dhcp_clientv4.Make(C)(OS.Time)(Random)(E)(I)(U)

  let or_error c name fn t =
    fn t
    >>= function
    | `Error e -> fail (Failure ("Error starting " ^ name))
    | `Ok t -> return t

  let start c net =
    or_error c "Ethif" E.connect net
    >>= fun e ->
    or_error c "Ipv4" I.connect e
    >>= fun i ->
    I.set_ipv4 i (Ipaddr.V4.of_string_exn "10.0.0.2")
    >>= fun () -> I.set_ipv4_netmask i (Ipaddr.V4.of_string_exn "255.255.255.0")
    >>= fun () -> I.set_ipv4_gateways i [Ipaddr.V4.of_string_exn "10.0.0.1"]
    >>= fun () ->
    or_error c "UDPv4" U.connect i
    >>= fun udp ->
    let dhcp, offers = D.create c i udp in
    or_error c "TCPv4" T.connect i
    >>= fun tcp ->
    N.listen net (
      E.input 
        ~ipv4:(
          I.input
            ~tcp:(
              T.input tcp ~listeners:
                (function
                  | 80 ->
                    Some (fun flow ->
                        let dst, dst_port = T.get_dest flow in
                        C.log_s c (green "new tcp connection from %s %d" (Ipaddr.V4.to_string dst) dst_port)
                        >>= fun () ->
                        T.read flow
                        >>= function
                        | `Ok b ->
                          C.log_s c (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
                          >>= fun () ->
                          T.close flow
                        | `Eof -> C.log_s c (red "read: eof")
                        | `Error e -> C.log_s c (red "read: error"))
                  | _ -> None
                ))
            ~udp:(
              U.input ~listeners:
                (fun ~dst_port ->
                   C.log c (blue "udp packet on port %d" dst_port);
                   D.listen dhcp ~dst_port)
                udp
            )
            ~default:(fun ~proto ~src ~dst _ -> return ())
            i)
        ~ipv6:(fun b -> C.log_s c (yellow "ipv6")) e)
end
