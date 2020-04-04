open Functoria
open Mirage_impl_ip
open Mirage_impl_misc
open Mirage_impl_random
module Key = Mirage_key

type 'a udp = UDP

type udpv4 = v4 udp

type udpv6 = v6 udp

let udp = Type.Type UDP

let udpv4 : udpv4 typ = udp

let udpv6 : udpv6 typ = udp

(* Value restriction ... *)
let udp_direct_func () =
  let packages_v = right_tcpip_library ~sublibs:[ "udp" ] "tcpip" in
  let connect _ modname = function
    | [ ip; _random ] -> Fmt.strf "%s.connect %s" modname ip
    | _ -> failwith (connect_err "udp" 2)
  in
  impl ~packages_v ~connect "Udp.Make" (ip @-> random @-> udp)

let direct_udp ?(random = default_random) ip = udp_direct_func () $ ip $ random

let udpv4_socket_conf ipv4_key =
  let keys = [ Key.v ipv4_key ] in
  let packages_v = right_tcpip_library ~sublibs:[ "udpv4-socket" ] "tcpip" in
  let build i =
    match get_target i with
    | `Unix | `MacOSX -> Action.ok ()
    | _ -> Action.error "UDPv4 socket not supported on non-UNIX targets."
  in
  let connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv4_key in
  impl ~keys ~packages_v ~build ~connect "Udpv4_socket" udpv4

let socket_udpv4 ?group ip = udpv4_socket_conf @@ Key.V4.socket ?group ip
