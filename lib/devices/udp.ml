module Action = Functoria.Action
open Functoria.DSL
open Ip
open Misc

type 'a udp = UDP
type udpv4v6 = v4v6 udp

let udp = Functoria.Type.Type UDP
let udpv4v6 : udpv4v6 typ = udp

(* Value restriction ... *)
let udp_direct_func () =
  let packages_v = right_tcpip_library ~sublibs:[ "udp" ] "tcpip" in
  let connect _ modname = function
    | [ ip ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> connect_err "udp" 1
  in
  impl ~packages_v ~connect "Udp.Make" (ip @-> udp)

let direct_udp ip = udp_direct_func () $ ip

let udpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key =
  let v = Runtime_arg.v in
  let runtime_args = [ v ipv4_only; v ipv6_only; v ipv4_key; v ipv6_key ] in
  let packages_v = right_tcpip_library ~sublibs:[ "udpv4v6-socket" ] "tcpip" in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "UDPv4v6 socket not supported on non-UNIX targets."
  in
  let connect _ modname = function
    | [ ipv4_only; ipv6_only; ipv4_key; ipv6_key ] ->
        code ~pos:__POS__ "%s.connect ~ipv4_only:%s ~ipv6_only:%s %s %s" modname
          ipv4_only ipv6_only ipv4_key ipv6_key
    | _ -> connect_err "udpv4v6_socket_conf" 4
  in
  impl ~runtime_args ~packages_v ~configure ~connect "Udpv4v6_socket" udpv4v6

let socket_udpv4v6 ?group ipv4 ipv6 =
  let ipv4 =
    match ipv4 with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  and ipv6 =
    match ipv6 with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  and ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  udpv4v6_socket_conf ~ipv4_only ~ipv6_only
    (Runtime_arg.V4.network ?group ipv4)
    (Runtime_arg.V6.network ?group ipv6)
