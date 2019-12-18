open Functoria
open Mirage_impl_ip
open Mirage_impl_misc
open Mirage_impl_random
open Rresult

module Key = Mirage_key
module Name = Functoria_app.Name

type 'a udp = UDP
type udpv4 = v4 udp
type udpv6 = v6 udp

let udp = Type UDP
let udpv4: udpv4 typ = udp
let udpv6: udpv6 typ = udp

(* Value restriction ... *)
let udp_direct_conf () = object
  inherit base_configurable
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
  inherit base_configurable
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

let socket_udpv4 ?group ip = impl (udpv4_socket_conf @@ Key.V4.socket ?group ip)
