open Functoria.DSL
open Ip
open Misc

type 'a icmp = ICMP
type icmpv4 = v4 icmp

let icmp = typ ICMP
let icmpv4 : icmpv4 typ = icmp

let icmpv4_direct () =
  let packages_v = right_tcpip_library ~sublibs:[ "icmpv4" ] "tcpip" in
  let connect _ modname = function
    | [ ip ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> connect_err "icmpv4" 1
  in
  impl ~packages_v ~connect "Icmpv4.Make" (ip @-> icmp)

let direct_icmpv4 ip = icmpv4_direct () $ ip
