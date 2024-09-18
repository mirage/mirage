open Functoria.DSL
open Ethernet
open Time
open Misc

type arpv4 = Arpv4

let arpv4 = typ Arpv4

let arp_conf =
  let packages =
    [ package ~min:"3.0.0" ~max:"4.0.0" ~sublibs:[ "mirage" ] "arp" ]
  in
  let connect _ modname = function
    | [ eth; _time ] -> code ~pos:__POS__ "%s.connect %s" modname eth
    | _ -> connect_err "arp" 2
  in
  let extra_deps = [ dep default_time ] in
  impl ~extra_deps ~packages ~connect "Arp.Make" (ethernet @-> arpv4)

let arp (eth : ethernet impl) = arp_conf $ eth
