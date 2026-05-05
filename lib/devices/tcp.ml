open Functoria.DSL
open Functoria.Action

type 'a tcp = TCP
type tcpv4v6 = Ip.v4v6 tcp

let tcp = Functoria.Type.Type TCP
let tcpv4v6 : tcpv4v6 typ = tcp

let utcp_direct_func name =
  let packages = [ package "utcp" ~sublibs:[ "mirage" ] ] in
  let connect _ modname = function
    | [ ip ] ->
        code ~pos:__POS__ "Lwt.return (%s.connect %S %s)" modname name ip
    | _ -> Misc.connect_err "utcp" 1
  in
  impl ~packages ~connect "Utcp_mirage.Make" (Ip.ip @-> tcp)

let tcp_direct_func _name =
  let packages = [ Ip.right_tcpip_library [ "tcp" ] ] in
  let connect _ modname = function
    | [ ip ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> Misc.connect_err "tcp" 1
  in
  impl ~packages ~connect "Tcp.Flow.Make" (Ip.ip @-> tcp)

let direct_tcp name ip =
  let use_utcp_key = Key.value @@ Key.utcp ~group:name () in
  let choose utcp = match utcp with true -> `Utcp | false -> `No in
  let use_utcp = Key.(pure choose $ use_utcp_key) in
  match_impl use_utcp
    [ (`Utcp, utcp_direct_func name $ ip) ]
    ~default:(tcp_direct_func name $ ip)

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
