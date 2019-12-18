open Functoria
open Mirage_impl_ip
open Mirage_impl_mclock
open Mirage_impl_misc
open Mirage_impl_random
open Mirage_impl_time
open Rresult

module Key = Mirage_key
module Name = Functoria_app.Name

type 'a tcp = TCP
type tcpv4 = v4 tcp
type tcpv6 = v6 tcp

let tcp = Type TCP
let tcpv4 : tcpv4 typ = tcp
let tcpv6 : tcpv6 typ = tcp

(* Value restriction ... *)
let tcp_direct_conf () = object
  inherit base_configurable
  method ty = (ip: 'a ip typ) @-> time @-> mclock @-> random @-> (tcp: 'a tcp typ)
  method name = "tcp"
  method module_name = "Tcp.Flow.Make"
  method! packages = right_tcpip_library ~sublibs:["tcp"] "tcpip"
  method! connect _ modname = function
    | [ip; _time; _clock; _random] -> Fmt.strf "%s.connect %s" modname ip
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
  method! connect _ modname _ = Fmt.strf "%s.connect %a" modname pp_key ipv4_key
end

let socket_tcpv4 ?group ip = impl (tcpv4_socket_conf @@ Key.V4.socket ?group ip)
