module Key = Mirage_key
open Functoria
open Mirage_impl_misc
open Mirage_impl_network

type ethernet = ETHERNET
let ethernet = Type ETHERNET

let ethernet_conf = object
  inherit base_configurable
  method ty = network @-> ethernet
  method name = "ethernet"
  method module_name = "Ethernet.Make"
  method! packages =
    Key.pure [ package ~min:"2.2.0" ~max:"3.0.0" "ethernet" ]
  method! connect _ modname = function
    | [ eth ] -> Fmt.str "%s.connect %s" modname eth
    | _ -> failwith (connect_err "ethernet" 1)
end

let etif_func = impl ethernet_conf
let etif network = etif_func $ network
