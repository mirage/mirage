open Functoria.DSL

type 'a icmp = ICMP
type icmpv4 = Ip.v4 icmp

let icmp = typ ICMP
let icmpv4 : icmpv4 typ = icmp

let icmpv4_direct () =
  let packages = [ Ip.right_tcpip_library [ "icmpv4" ] ] in
  let connect _ modname = function
    | [ ip ] -> code ~pos:__POS__ "%s.connect %s" modname ip
    | _ -> Misc.connect_err "icmpv4" 1
  in
  impl ~packages ~connect "Icmpv4.Make" (Ip.ip @-> icmp)

let direct_icmpv4 ip = icmpv4_direct () $ ip
