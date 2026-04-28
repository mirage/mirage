open Functoria.DSL
open Functoria.Action

type 'a tcp = TCP
type tcpv4v6 = Ip.v4v6 tcp

let tcp = Functoria.Type.Type TCP
let tcpv4v6 : tcpv4v6 typ = tcp

let tcp_direct_func ?(use_utcp = false) name =
  let packages =
    if use_utcp then [ package "utcp" ~sublibs:[ "mirage" ] ]
    else [ Ip.right_tcpip_library [ "tcp" ] ]
  in
  let connect _ modname = function
    | [ ip ] ->
        if use_utcp then
          code ~pos:__POS__ "Lwt.return (%s.connect %S %s)" modname name ip
        else code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> Misc.connect_err "tcp" 1
  in
  let modu = if use_utcp then "Utcp_mirage.Make" else "Tcp.Flow.Make" in
  impl ~packages ~connect modu (Ip.ip @-> tcp)

let direct_tcp ?use_utcp name ip = tcp_direct_func ?use_utcp name $ ip

let tcpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key =
  let v = Runtime_arg.v in
  let runtime_args = [ v ipv4_only; v ipv6_only; v ipv4_key; v ipv6_key ] in
  let packages = [ Ip.right_tcpip_library [ "tcpv4v6-socket" ] ] in
  let configure i =
    match Misc.get_target i with
    | `Unix | `MacOSX -> ok ()
    | _ -> error "TCPv4v6 socket not supported on non-UNIX targets."
  in
  let connect _ modname = function
    | [ ipv4_only; ipv6_only; ipv4_key; ipv6_key ] ->
        code ~pos:__POS__ "%s.connect ~ipv4_only:%s ~ipv6_only:%s %s %s" modname
          ipv4_only ipv6_only ipv4_key ipv6_key
    | _ -> Misc.connect_err "tcpv4v6_socket_conf" 4
  in
  impl ~packages ~configure ~runtime_args ~connect "Tcpv4v6_socket" tcpv4v6
