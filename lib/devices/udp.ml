module Action = Functoria.Action
open Functoria.DSL
open Ip
open Misc
open Random

type 'a udp = UDP
type udpv4v6 = v4v6 udp

let udp = Functoria.Type.Type UDP
let udpv4v6 : udpv4v6 typ = udp

(* Value restriction ... *)
let udp_func ip random =
  let packages_v =
    Key.(if_ is_unix)
      (right_tcpip_library ~sublibs:[ "udp" ; "udp-unix" ] "tcpip")
      (right_tcpip_library ~sublibs:[ "udp" ; "udp-direct" ] "tcpip")
  in
  let connect _ modname = function
    | [ ip ; _random ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> connect_err "udp" 2
  in
  let extra_deps = [ dep ip ; dep random ] in
  impl ~packages_v ~extra_deps ~connect "Udp" udp

let udp_impl ?(random = default_random) ip = udp_func ip random
