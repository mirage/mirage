open Functoria
open Mirage_impl_ip
open Mirage_impl_mclock
open Mirage_impl_misc
open Mirage_impl_random
open Mirage_impl_time
module Key = Mirage_key

type 'a tcp = TCP

type tcpv4 = v4 tcp

type tcpv6 = v6 tcp

type tcpv4v6 = v4v6 tcp

let tcp = Type.Type TCP

let tcpv4 : tcpv4 typ = tcp

let tcpv6 : tcpv6 typ = tcp

let tcpv4v6 : tcpv4v6 typ = tcp

(* this needs to be a function due to the value restriction. *)
let tcp_direct_func () =
  let packages_v = right_tcpip_library ~sublibs:[ "tcp" ] "tcpip" in
  let connect _ modname = function
    | [ ip; _time; _clock; _random ] -> Fmt.str "%s.connect %s" modname ip
    | _ -> failwith (connect_err "direct tcp" 4)
  in
  impl ~packages_v ~connect "Tcp.Flow.Make"
    (ip @-> time @-> mclock @-> random @-> tcp)

let direct_tcp ?(mclock = default_monotonic_clock) ?(time = default_time)
    ?(random = default_random) ip =
  tcp_direct_func () $ ip $ time $ mclock $ random

let tcpv4_socket_conf ipv4_key =
  let keys = [ Key.v ipv4_key ] in
  let packages_v = right_tcpip_library ~sublibs:[ "tcpv4-socket" ] "tcpip" in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "TCPv4 socket not supported on non-UNIX targets."
  in
  let connect _ modname _ = Fmt.str "%s.connect %a" modname pp_key ipv4_key in
  impl ~packages_v ~configure ~keys ~connect "Tcpv4_socket" tcpv4

let socket_tcpv4 ?group ip =
  let ip =
    match ip with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  in
  tcpv4_socket_conf @@ Key.V4.network ?group ip

let tcpv6_socket_conf ipv6_key =
  let keys = [ Key.v ipv6_key ] in
  let packages_v = right_tcpip_library ~sublibs:[ "tcpv6-socket" ] "tcpip" in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "TCPv6 socket not supported on non-UNIX targets."
  in
  let connect _ modname _ = Fmt.str "%s.connect %a" modname pp_key ipv6_key in
  impl ~packages_v ~configure ~keys ~connect "Tcpv6_socket" tcpv6

let socket_tcpv6 ?group ip =
  let ip =
    match ip with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  in
  tcpv6_socket_conf @@ Key.V6.network ?group ip

let tcpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key =
  let keys =
    [ Key.v ipv4_only; Key.v ipv6_only; Key.v ipv4_key; Key.v ipv6_key ]
  in
  let packages_v = right_tcpip_library ~sublibs:[ "tcpv4v6-socket" ] "tcpip" in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "TCPv4v6 socket not supported on non-UNIX targets."
  in
  let connect _ modname _ =
    Fmt.str "%s.connect ~ipv4_only:%a ~ipv6_only:%a %a %a" modname pp_key
      ipv4_only pp_key ipv6_only pp_key ipv4_key pp_key ipv6_key
  in
  impl ~packages_v ~configure ~keys ~connect "Tcpv4v6_socket" tcpv4v6

let socket_tcpv4v6 ?group ipv4 ipv6 =
  let ipv4 =
    match ipv4 with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  and ipv6 =
    match ipv6 with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  and ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group () in
  tcpv4v6_socket_conf ~ipv4_only ~ipv6_only
    (Key.V4.network ?group ipv4)
    (Key.V6.network ?group ipv6)
