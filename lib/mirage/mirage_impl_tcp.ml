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

let tcp = Type.Type TCP

let tcpv4 : tcpv4 typ = tcp

let tcpv6 : tcpv6 typ = tcp

(* this needs to be a function due to the value restriction. *)
let tcp_direct_func () =
  let packages_v = right_tcpip_library ~sublibs:[ "tcp" ] "tcpip" in
  let connect _ modname = function
    | [ ip; _time; _clock; _random ] -> Fmt.strf "%s.connect %s" modname ip
    | _ -> failwith (connect_err "direct tcp" 4)
  in
  impl ~packages_v ~connect "Tcp.Flow.Make"
    (ip @-> time @-> mclock @-> random @-> tcp)

let direct_tcp ?(clock = default_monotonic_clock) ?(random = default_random)
    ?(time = default_time) ip =
  tcp_direct_func () $ ip $ time $ clock $ random

let tcpv4_socket_conf ipv4_key =
  let keys = [ Key.v ipv4_key ] in
  let packages_v = right_tcpip_library ~sublibs:[ "tcpv4-socket" ] "tcpip" in
  let build i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "TCPv4 socket not supported on non-UNIX targets."
  in
  let connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv4_key in
  impl ~packages_v ~build ~keys ~connect "Tcpv4_socket" tcpv4

let socket_tcpv4 ?group ip = tcpv4_socket_conf @@ Key.V4.socket ?group ip
