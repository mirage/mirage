open Functoria.DSL
open Ip
open Mclock
open Misc
open Random
open Time
open Functoria.Action

type 'a tcp = TCP
type tcpv4v6 = v4v6 tcp

let packages = right_tcpip_library ~sublibs:[ "tcp" ] "tcpip"
let tcp = { Functoria.Type.packages; typ = Type TCP }

let tcpv4v6 : tcpv4v6 typ =
  let packages = right_tcpip_library ~sublibs:[ "tcpv4v6-socket" ] "tcpip" in
  typ ~packages TCP

(* this needs to be a function due to the value restriction. *)
let tcp_direct_func () =
  let packages = right_tcpip_library ~sublibs:[ "tcp" ] "tcpip" in
  let connect _ modname = function
    | [ ip; _time; _clock; _random ] ->
        code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> connect_err "tcp" 4
  in
  impl ~packages ~connect "Tcp.Flow.Make"
    (ip @-> time @-> mclock @-> random @-> tcp)

let direct_tcp ?(mclock = default_monotonic_clock) ?(time = default_time)
    ?(random = default_random) ip =
  tcp_direct_func () $ ip $ time $ mclock $ random

let tcpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key =
  let v = Runtime_arg.v in
  let runtime_args = [ v ipv4_only; v ipv6_only; v ipv4_key; v ipv6_key ] in
  let packages = right_tcpip_library ~sublibs:[ "tcpv4v6-socket" ] "tcpip" in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> ok ()
    | _ -> error "TCPv4v6 socket not supported on non-UNIX targets."
  in
  let connect _ modname = function
    | [ ipv4_only; ipv6_only; ipv4_key; ipv6_key ] ->
        code ~pos:__POS__ "%s.connect ~ipv4_only:%s ~ipv6_only:%s %s %s" modname
          ipv4_only ipv6_only ipv4_key ipv6_key
    | _ -> connect_err "tcpv4v6_socket_conf" 4
  in
  impl ~packages ~configure ~runtime_args ~connect "Tcpv4v6_socket" tcpv4v6

let socket_tcpv4v6 ?group ipv4 ipv6 =
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
  tcpv4v6_socket_conf ~ipv4_only ~ipv6_only
    (Runtime_arg.V4.network ?group ipv4)
    (Runtime_arg.V6.network ?group ipv6)
