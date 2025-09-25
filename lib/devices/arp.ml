open Functoria.DSL

type arpv4 = Arpv4

let arpv4 = typ Arpv4

let arp_conf =
  let packages =
    [ package ~min:"4.0.0" ~max:"5.0.0" ~sublibs:[ "mirage" ] "arp" ]
  in
  let connect _ modname = function
    | [ eth ] -> code ~pos:__POS__ "%s.connect %s" modname eth
    | _ -> Misc.connect_err "arp" 1
  in
  impl ~packages ~connect "Arp.Make" (Ethernet.ethernet @-> arpv4)

let arp (eth : Ethernet.ethernet impl) = arp_conf $ eth
