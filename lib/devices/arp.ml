open Functoria.DSL
open Ethernet
open Misc

type arpv4 = Arpv4

let arpv4 = typ Arpv4

let arp_conf eth =
  let packages =
    [ package ~min:"3.0.0" ~max:"4.0.0" ~sublibs:[ "mirage" ] "arp" ]
  in
  let connect _ modname = function
    | [ eth ] -> code ~pos:__POS__ "%s.connect %s" modname eth
    | _ -> connect_err "arp" 1
  in
  let extra_deps = [ dep eth ] in
  impl ~packages ~extra_deps ~connect "Arp" arpv4

let arp (eth : ethernet impl) = arp_conf eth
