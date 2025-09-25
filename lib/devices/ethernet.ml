open Functoria.DSL

type ethernet = ETHERNET

let ethernet = typ ETHERNET

let ethif_conf =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "ethernet" ] in
  let connect _ m = function
    | [ eth ] -> code ~pos:__POS__ "%s.connect %s" m eth
    | _ -> Misc.connect_err "etif" 1
  in
  impl ~packages ~connect "Ethernet.Make" (Network.network @-> ethernet)

let ethif network = ethif_conf $ network
