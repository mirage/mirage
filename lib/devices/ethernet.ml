open Functoria.DSL
open Misc

type ethernet = ETHERNET

let ethernet = typ ETHERNET

let etif_conf network =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "ethernet" ] in
  let connect _ m = function
    | [ eth ] -> code ~pos:__POS__ "%s.connect %s" m eth
    | _ -> connect_err "etif" 1
  in
  let extra_deps = [ dep network ] in
  impl ~packages ~extra_deps ~connect "Ethernet" ethernet

let etif network = etif_conf network
