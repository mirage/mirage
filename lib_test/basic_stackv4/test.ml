open V1_LWT
open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Direct (C: CONSOLE) (N: NETWORK) = struct

  module E = Ethif.Make(N)
  module I = Ipv4.Make(E)
  module U = Udpv4.Make(I)
  module T = Tcpv4.Flow.Make(I)(OS.Time)(Clock)(Random)
  module S = Manager.Make(C)(OS.Time)(Random)(N)(E)(I)(U)(T)

  let start console interface =
    let config = {
      V1_LWT.name="teststack";
      console;
      interface;
      mode=`IPv4 (
        Ipaddr.V4.of_string_exn "10.0.0.2",
        Ipaddr.V4.of_string_exn "255.255.255.0",
        [Ipaddr.V4.of_string_exn "10.0.0.1"]) 
    } in
    S.connect config 
    >>= function
    | `Error err -> fail (Failure "Error")
    | `Ok s ->
       S.listen_udpv4 s 53 (
         fun ~src ~dst ~src_port buf ->
           C.log_s console "got udp on 53"
       );
       S.listen_tcpv4 s 80 (
         fun flow ->
           let dst, dst_port = T.get_dest flow in
           C.log_s console (green "new tcp connection from %s %d" (Ipaddr.V4.to_string dst) dst_port)
           >>= fun () ->
           T.read flow
           >>= function
           | `Ok b ->
             C.log_s console (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
             >>= fun () ->
             T.close flow
           | `Eof -> C.log_s console (red "read: eof")
           | `Error e -> C.log_s console (red "read: error")
       );
       S.listen s
end

module Socket (C: CONSOLE) = struct

  module S = Tcpip_stack_socket.Make(C)
  module T = Tcpv4_socket

  let start console =
    let config = {
      V1_LWT.name="teststack";
      console;
      interface=[Ipaddr.V4.any];
      mode=()
    } in
    S.connect config
    >>= function
    | `Error err -> fail (Failure "Error")
    | `Ok s ->
       S.listen_udpv4 s 53 (
         fun ~src ~dst ~src_port buf ->
           C.log_s console "got udp on 53"
       );
       S.listen_tcpv4 s 80 (
         fun flow ->
           let dst, dst_port = T.get_dest flow in
           C.log_s console (green "new tcp connection from %s %d" (Ipaddr.V4.to_string dst) dst_port)
           >>= fun () ->
           T.read flow
           >>= function
           | `Ok b ->
             C.log_s console (yellow "read: %d\n%s" (Cstruct.len b) (Cstruct.to_string b))
             >>= fun () ->
             T.close flow
           | `Eof -> C.log_s console (red "read: eof")
           | `Error e -> C.log_s console (red "read: error")
       );
       S.listen s
end
