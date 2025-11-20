module Action = Functoria.Action
open Functoria.DSL

type 'a udp = UDP
type udpv4v6 = Ip.v4v6 udp

let udp = Functoria.Type.Type UDP
let udpv4v6 : udpv4v6 typ = udp

(* Value restriction ... *)
let udp_direct_func () =
  let packages = [ Ip.right_tcpip_library [ "udp" ] ] in
  let connect _ modname = function
    | [ ip ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> Misc.connect_err "udp" 1
  in
  impl ~packages ~connect "Udp.Make" (Ip.ip @-> udp)

let direct_udp ip = udp_direct_func () $ ip

let udpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key =
  let v = Runtime_arg.v in
  let runtime_args = [ v ipv4_only; v ipv6_only; v ipv4_key; v ipv6_key ] in
  let packages = [ Ip.right_tcpip_library [ "udpv4v6-socket" ] ] in
  let configure i =
    match Misc.get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "UDPv4v6 socket not supported on non-UNIX targets."
  in
  let connect _ modname = function
    | [ ipv4_only; ipv6_only; ipv4_key; ipv6_key ] ->
        code ~pos:__POS__ "%s.connect ~ipv4_only:%s ~ipv6_only:%s %s %s" modname
          ipv4_only ipv6_only ipv4_key ipv6_key
    | _ -> Misc.connect_err "udpv4v6_socket_conf" 4
  in
  impl ~runtime_args ~packages ~configure ~connect "Udpv4v6_socket" udpv4v6
