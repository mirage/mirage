open Functoria
open Mirage_impl_ip
open Mirage_impl_misc
open Mirage_impl_random
module Key = Mirage_key

type 'a udp = UDP
type udpv4v6 = v4v6 udp

let udp = Type.Type UDP
let udpv4v6 : udpv4v6 typ = udp

(* Value restriction ... *)
let udp_direct_func () =
  let packages_v = right_tcpip_library ~sublibs:[ "udp" ] "tcpip" in
  let connect _ modname = function
    | [ ip; _random ] -> Fmt.str "%s.connect %s" modname ip
    | _ -> failwith (connect_err "udp" 2)
  in
  impl ~packages_v ~connect "Udp.Make" (ip @-> random @-> udp)

let direct_udp ?(random = default_random) ip = udp_direct_func () $ ip $ random

let udpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key =
  let keys =
    [ Key.v ipv4_only; Key.v ipv6_only; Key.v ipv4_key; Key.v ipv6_key ]
  in
  let packages_v = right_tcpip_library ~sublibs:[ "udpv4v6-socket" ] "tcpip" in
  let configure i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "UDPv4v6 socket not supported on non-UNIX targets."
  in
  let connect _ modname _ =
    Fmt.str "%s.connect ~ipv4_only:%a ~ipv6_only:%a %a %a" modname pp_key
      ipv4_only pp_key ipv6_only pp_key ipv4_key pp_key ipv6_key
  in
  impl ~keys ~packages_v ~configure ~connect "Udpv4v6_socket" udpv4v6

let socket_udpv4v6 ?group ipv4 ipv6 =
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
  udpv4v6_socket_conf ~ipv4_only ~ipv6_only
    (Key.V4.network ?group ipv4)
    (Key.V6.network ?group ipv6)
