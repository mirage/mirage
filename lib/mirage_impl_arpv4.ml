module Key = Mirage_key
open Functoria
open Mirage_impl_ethernet
open Mirage_impl_time
open Mirage_impl_misc

type arpv4 = Arpv4
let arpv4 = Type Arpv4

let arp_conf = object
  inherit base_configurable
  method ty = ethernet @-> time @-> arpv4
  method name = "arp"
  method module_name = "Arp.Make"
  method! packages =
    Key.pure [ package ~min:"3.0.0" ~max:"4.0.0" ~sublibs:["mirage"] "arp" ]
  method! connect _ modname = function
    | [ eth ; _time ] -> Fmt.str "%s.connect %s" modname eth
    | _ -> failwith (connect_err "arp" 3)
end

let arp_func = impl arp_conf
let arp
    ?(time = default_time)
    (eth : ethernet impl) =
  arp_func $ eth $ time
