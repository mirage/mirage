module Key = Mirage_key
module Name = Functoria_app.Name
open Functoria
open Mirage_impl_ip
open Mirage_impl_mclock
open Mirage_impl_misc
open Mirage_impl_random
open Mirage_impl_time
open Rresult

type 'a tcp = TCP
type tcpv4 = v4 tcp
type tcpv6 = v6 tcp
type tcpv4v6 = v4v6 tcp

let tcp = Type TCP
let tcpv4 : tcpv4 typ = tcp
let tcpv6 : tcpv6 typ = tcp
let tcpv4v6 : tcpv4v6 typ = tcp

(* Value restriction ... *)
let tcp_direct_conf () = object
  inherit base_configurable
  method ty = (ip: 'a ip typ) @-> time @-> mclock @-> random @-> (tcp: 'a tcp typ)
  method name = "tcp"
  method module_name = "Tcp.Flow.Make"
  method! packages = right_tcpip_library ~sublibs:["tcp"] "tcpip"
  method! connect _ modname = function
    | [ip; _time; _clock; _random] -> Fmt.str "%s.connect %s" modname ip
    | _ -> failwith (connect_err "direct tcp" 4)
end

(* Value restriction ... *)
let tcp_direct_func () = impl (tcp_direct_conf ())

let direct_tcp
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time) ip =
  tcp_direct_func () $ ip $ time $ clock $ random

let tcpv4_socket_conf ipv4_key = object
  inherit base_configurable
  method ty = tcpv4
  val name = Name.create "tcpv4_socket" ~prefix:"tcpv4_socket"
  method name = name
  method module_name = "Tcpv4_socket"
  method! keys = [ Key.abstract ipv4_key ]
  method! packages = right_tcpip_library ~sublibs:["tcpv4-socket"] "tcpip"
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _  -> R.error_msg "TCPv4 socket not supported on non-UNIX targets."
  method! connect _ modname _ = Fmt.str "%s.connect %a" modname pp_key ipv4_key
end

let keyed_socket_tcpv4 key = impl (tcpv4_socket_conf key)

let socket_tcpv4 ?group ip =
  let ip = match ip with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  in
  keyed_socket_tcpv4 @@ Key.V4.network ?group ip

let tcpv6_socket_conf ipv6_key = object
  inherit base_configurable
  method ty = tcpv6
  val name = Name.create "tcpv6_socket" ~prefix:"tcpv4_socket"
  method name = name
  method module_name = "Tcpv6_socket"
  method! keys = [ Key.abstract ipv6_key ]
  method! packages = right_tcpip_library ~sublibs:["tcpv6-socket"] "tcpip"
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _  -> R.error_msg "TCPv6 socket not supported on non-UNIX targets."
  method! connect _ modname _ = Fmt.str "%s.connect %a" modname pp_key ipv6_key
end

let keyed_socket_tcpv6 key = impl (tcpv6_socket_conf key)

let socket_tcpv6 ?group ip =
  let ip = match ip with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  in
  keyed_socket_tcpv6 @@ Key.V6.network ?group ip

let tcpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4_key ipv6_key = object
  inherit base_configurable
  method ty = tcpv4v6
  val name = Name.create "tcpv4v6_socket" ~prefix:"tcpv4v6_socket"
  method name = name
  method module_name = "Tcpv4v6_socket"
  method! keys = [ Key.abstract ipv4_only ; Key.abstract ipv6_only ; Key.abstract ipv4_key ; Key.abstract ipv6_key ]
  method! packages = right_tcpip_library ~sublibs:["tcpv4v6-socket"] "tcpip"
  method! configure i =
    match get_target i with
    | `Unix | `MacOSX -> R.ok ()
    | _  -> R.error_msg "TCPv4v6 socket not supported on non-UNIX targets."
  method! connect _ modname _ =
    Fmt.str "%s.connect ~ipv4_only:%a ~ipv6_only:%a %a %a"
      modname
      pp_key ipv4_only pp_key ipv6_only
      pp_key ipv4_key pp_key ipv6_key
end

let keyed_socket_tcpv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 =
  impl (tcpv4v6_socket_conf ~ipv4_only ~ipv6_only ipv4 ipv6)

let socket_tcpv4v6 ?group ipv4 ipv6 =
  let ipv4 = match ipv4 with
    | None -> Ipaddr.V4.Prefix.global
    | Some ip -> Ipaddr.V4.Prefix.make 32 ip
  and ipv6 = match ipv6 with
    | None -> None
    | Some ip -> Some (Ipaddr.V6.Prefix.make 128 ip)
  and ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group ()
  in
  keyed_socket_tcpv4v6 ~ipv4_only ~ipv6_only (Key.V4.network ?group ipv4) (Key.V6.network ?group ipv6)
