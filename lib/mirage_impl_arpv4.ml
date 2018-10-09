module Key = Mirage_key
open Functoria
open Mirage_impl_ethernet
open Mirage_impl_mclock
open Mirage_impl_time
open Mirage_impl_misc

type arpv4 = Arpv4
let arpv4 = Type Arpv4

let arpv4_conf = object
  inherit base_configurable
  method ty = ethernet @-> mclock @-> time @-> arpv4
  method name = "arpv4"
  method module_name = "Arpv4.Make"
  method! packages = Key.pure [ package ~min:"3.5.0" ~sublibs:["arpv4"] "tcpip" ]
  method! connect _ modname = function
    | [ eth ; clock ; _time ] -> Fmt.strf "%s.connect %s %s" modname eth clock
    | _ -> failwith (connect_err "arpv4" 3)
end

let arp_func = impl arpv4_conf
let arp
    ?(clock = default_monotonic_clock)
    ?(time = default_time)
    (eth : ethernet impl) =
  arp_func $ eth $ clock $ time


let farp_conf = object
  inherit base_configurable
  method ty = ethernet @-> mclock @-> time @-> arpv4
  method name = "arp"
  method module_name = "Arp.Make"
  method! packages = Key.pure [ package ~min:"0.2.0" ~sublibs:["mirage"] "arp" ]
  method! connect _ modname = function
    | [ eth ; clock ; _time ] -> Fmt.strf "%s.connect %s %s" modname eth clock
    | _ -> failwith (connect_err "arp" 3)
end

let farp_func = impl farp_conf
let farp
    ?(clock = default_monotonic_clock)
    ?(time = default_time)
    (eth : ethernet impl) =
  farp_func $ eth $ clock $ time
