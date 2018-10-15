open Functoria
open Mirage_impl_ip
open Mirage_impl_misc

type 'a icmp = ICMP
type icmpv4 = v4 icmp

let icmp = Type ICMP
let icmpv4: icmpv4 typ = icmp

let icmpv4_direct_conf () = object
  inherit base_configurable
  method ty : ('a ip -> 'a icmp) typ = ip @-> icmp
  method name = "icmpv4"
  method module_name = "Icmpv4.Make"
  method! packages = right_tcpip_library ~min:"3.5.0" ~sublibs:["icmpv4"] "tcpip"
  method! connect _ modname = function
    | [ ip ] -> Fmt.strf "%s.connect %s" modname ip
    | _  -> failwith (connect_err "icmpv4" 1)
end

let icmpv4_direct_func () = impl (icmpv4_direct_conf ())
let direct_icmpv4 ip = icmpv4_direct_func () $ ip
