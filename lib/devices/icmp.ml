open Functoria.DSL
open Ip
open Misc

type 'a icmp = ICMP
type icmpv4 = v4 icmp

let icmp = typ ICMP
let icmpv4 : icmpv4 typ = icmp

let icmpv4_impl ip =
  let packages_v =
    Key.(if_ is_unix)
      (right_tcpip_library ~sublibs:[ "icmpv4" ; "icmpv4-unix" ] "tcpip")
      (right_tcpip_library ~sublibs:[ "icmpv4" ; "icmpv4-direct" ] "tcpip")
  in
  let connect _ modname = function
    | [ ip ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> connect_err "icmpv4" 1
  in
  let extra_deps = [ dep ip ] in
  impl ~extra_deps ~packages_v ~connect "Icmpv4" icmp
