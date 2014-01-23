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

  let start c net =
    E.connect net
    >>= function
    |`Error _ -> C.log_s c (red "Ethif error")
    |`Ok e -> begin
        I.connect e
        >>= function
        |`Error _ -> C.log_s c (red "IPv4 err")
        |`Ok i ->
          I.set_ip i (Ipaddr.V4.of_string_exn "10.0.0.2")
          >>= fun () -> I.set_netmask i (Ipaddr.V4.of_string_exn "255.255.255.0")
          >>= fun () -> I.set_gateways i [Ipaddr.V4.of_string_exn "10.0.0.1"]
          >>= fun () ->
          U.connect i
          >>= function
          |`Error _ -> C.log_s c (red "UDPv4 err")
          |`Ok udp ->
            T.connect i
            >>= function
            |`Error _ -> C.log_s c (red "TCPv4 err")
            |`Ok tcp ->
              (* Listen on TCP port 80 *)
              let _ = 
                T.listen tcp 80
                  (fun (dst,dst_port) flow ->
                     C.log_s c (green "new tcp connection from %s %d" (Ipaddr.V4.to_string dst) dst_port)
                     >>= fun () ->
                     T.read flow
                     >>= function
                     | `Ok b ->
                          C.log_s c (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
                          >>= fun () ->
                          T.close flow
                     | `Eof -> C.log_s c (red "read: eof")
                     | `Error e -> C.log_s c (red "read: error")
                  )
              in
              N.listen net (
                E.input 
                  ~ipv4:(
                    I.input
                      ~tcp:(fun ~src ~dst b ->
                          C.log_s c (green "tcp packet")
                          >>= fun () ->
                          T.input tcp ~src ~dst b 
                        )
                      ~udp:(
                        U.input ~listeners:
                          (fun ~dst_port ->
                             C.log c (blue "udp packet on port %d" dst_port);
                             None)
                          udp
                      ) i)
                  ~ipv6:(fun b -> C.log_s c (yellow "ipv6")) e)
      end
end
