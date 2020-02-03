module Key = Mirage_key
open Functoria
open Mirage_impl_misc
open Mirage_impl_network

type ethernet = ETHERNET

let ethernet = Type.v ETHERNET

let etif_conf =
  let packages = [ package ~min:"2.2.0" ~max:"3.0.0" "ethernet" ] in
  let connect _ m = function
    | [ eth ] -> Fmt.strf "%s.connect %s" m eth
    | _ -> failwith (connect_err "ethernet" 1)
  in
  impl ~packages ~connect "Ethernet.Make" (network @-> ethernet)

let etif network = etif_conf $ network
