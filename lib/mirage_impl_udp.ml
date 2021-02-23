module Key = Mirage_key
module Name = Functoria_app.Name
open Functoria
open Mirage_impl_ip
open Mirage_impl_misc
open Mirage_impl_random
open Rresult

type 'a udp = UDP
type udpv4 = v4 udp
type udpv6 = v6 udp
type udpv4v6 = v4v6 udp

let udp = Type UDP
let udpv4: udpv4 typ = udp
let udpv6: udpv6 typ = udp
let udpv4v6: udpv4v6 typ = udp

(* Value restriction ... *)
let udp_direct_conf () = object
  inherit [_] base_configurable
  method ty = (ip: 'a ip typ) @-> random @-> (udp: 'a udp typ)
  method name = "udp"
  method module_name = "Udp.Make"
  method! packages = right_tcpip_library ~sublibs:["udp"] "tcpip"
  method! connect _ modname = function
    | [ ip; _random ] -> Fmt.strf "%s.connect %s" modname ip
    | _  -> failwith (connect_err "udp" 2)
end

(* Value restriction ... *)
let udp_direct_func () = impl (udp_direct_conf ())
let direct_udp ?(random=default_random) ip = udp_direct_func () $ ip $ random

let udpv4_socket_conf ipv4_key = object
  inherit [_] base_configurable
  method ty = udpv4
  val name = Name.create "udpv4_socket" ~prefix:"udpv4_socket"
  method name = name
  method module_name = "Udpv4_socket"
  method! keys = [ Key.abstract ipv4_key ]
  method! packages =
    right_tcpip_library ~sublibs:["udpv4-socket"] "tcpip"
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _ -> R.error_msg "UDPv4 socket not supported on non-UNIX targets."
  method! connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv4_key
end

let keyed_socket_udpv4 key = impl (udpv4_socket_conf key)

let socket_udpv4 ?group ip =
  let ip = match ip with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  in
  keyed_socket_udpv4 @@ Key.V4.network ?group ip

let udpv6_socket_conf ipv6_key = object
  inherit [_] base_configurable
  method ty = udpv6
  val name = Name.create "udpv6_socket" ~prefix:"udpv6_socket"
  method name = name
  method module_name = "Udpv6_socket"
  method! keys = [ Key.abstract ipv6_key ]
  method! packages =
    right_tcpip_library ~sublibs:["udpv6-socket"] "tcpip"
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _ -> R.error_msg "UDPv6 socket not supported on non-UNIX targets."
  method! connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv6_key
end

let keyed_socket_udpv6 key = impl (udpv6_socket_conf key)

let socket_udpv6 ?group ip =
  let ip = match ip with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  in
  keyed_socket_udpv6 @@ Key.V6.network ?group ip

let udpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key = object
  inherit [_] base_configurable
  method ty = udpv4v6
  val name = Name.create "udpv4v6_socket" ~prefix:"udpv4v6_socket"
  method name = name
  method module_name = "Udpv4v6_socket"
  method! keys = [ Key.abstract ipv4_only ; Key.abstract ipv6_only ; Key.abstract ipv4_key ; Key.abstract ipv6_key ]
  method! packages =
    right_tcpip_library ~sublibs:["udpv4v6-socket"] "tcpip"
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _ -> R.error_msg "UDPv4v6 socket not supported on non-UNIX targets."
  method! connect _ modname _ =
    Fmt.strf "%s.connect ~ipv4_only:%a ~ipv6_only:%a %a %a"
      modname
      pp_key ipv4_only pp_key ipv6_only
      pp_key ipv4_key pp_key ipv6_key
end

let keyed_socket_udpv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 =
  impl (udpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4 ipv6)

let socket_udpv4v6 ?group ipv4 ipv6 =
  let ipv4 = match ipv4 with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  and ipv6 = match ipv6 with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  and ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group ()
  in
  keyed_socket_udpv4v6 ~ipv4_only ~ipv6_only (Key.V4.network ?group ipv4) (Key.V6.network ?group ipv6)
