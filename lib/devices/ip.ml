open Functoria.DSL
open Arp
open Ethernet
open Misc
open Network
open Qubesdb

type v4
type v6
type v4v6
type 'a ip = IP
type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip

let ip = Functoria.Type.Type IP
let ipv4 : ipv4 typ = ip
let ipv6 : ipv6 typ = ip
let ipv4v6 : ipv4v6 typ = ip

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}
(** Types for IPv4 manual configuration. *)

(* convenience function for linking tcpip.unix for checksums *)
let right_tcpip_library ?libs ~sublibs pkg =
  let min = "9.0.0" and max = "10.0.0" in
  Key.pure [ package ~min ~max ?libs ~sublibs pkg ]

let ipv4_keyed_conf ~ip ~gateway ~no_init () =
  let packages_v = right_tcpip_library ~sublibs:[ "ipv4" ] "tcpip" in
  let runtime_args = Runtime_arg.[ v ip; v gateway; v no_init ] in
  let connect _ modname = function
    | [ etif; arp; ip; gateway; no_init ] ->
        code ~pos:__POS__
          "%s.connect@[~no_init:%s@ ~cidr:%s@ ?gateway:%s@ %s@ %s@]" modname
          no_init ip gateway etif arp
    | _ -> connect_err "ipv4 keyed" 5
  in
  impl ~packages_v ~runtime_args ~connect "Static_ipv4.Make"
    (ethernet @-> arpv4 @-> ipv4)

let ipv4_dhcp_conf =
  let packages =
    [ package ~min:"2.0.0" ~max:"3.0.0" ~sublibs:[ "mirage" ] "charrua-client" ]
  in
  let connect _ modname = function
    | [ network; ethernet; arp ] ->
        code ~pos:__POS__ "%s.connect@[@ %s@ %s@ %s@]" modname network ethernet
          arp
    | _ -> connect_err "ipv4 dhcp" 3
  in
  impl ~packages ~connect "Dhcp_ipv4.Make"
    (network @-> ethernet @-> arpv4 @-> ipv4)

let ipv4_of_dhcp net ethif arp = ipv4_dhcp_conf $ net $ ethif $ arp

let keyed_create_ipv4 ?group ?config ~no_init etif arp =
  let network, gateway =
    match config with
    | None -> (Ipaddr.V4.Prefix.of_string_exn "10.0.0.2/24", None)
    | Some { network; gateway } -> (network, gateway)
  in
  let ip = Runtime_arg.V4.network ?group network
  and gateway = Runtime_arg.V4.gateway ?group gateway in
  ipv4_keyed_conf ~ip ~gateway ~no_init () $ etif $ arp

let create_ipv4 ?group ?config etif arp =
  let network, gateway =
    match config with
    | None -> (Ipaddr.V4.Prefix.of_string_exn "10.0.0.2/24", None)
    | Some { network; gateway } -> (network, gateway)
  in
  let ip = Runtime_arg.V4.network ?group network
  and gateway = Runtime_arg.V4.gateway ?group gateway
  and no_init = Runtime_arg.ipv6_only ?group () in
  ipv4_keyed_conf ~ip ~gateway ~no_init () $ etif $ arp

type ipv6_config = {
  network : Ipaddr.V6.Prefix.t;
  gateway : Ipaddr.V6.t option;
}
(** Types for IP manual configuration. *)

let ipv4_qubes_conf =
  let packages = [ package ~min:"2.0.0" ~max:"3.0.0" "mirage-qubes-ipv4" ] in
  let connect _ modname = function
    | [ db; etif; arp ] ->
        code ~pos:__POS__ "%s.connect@[@ %s@ %s@ %s@]" modname db etif arp
    | _ -> connect_err "qubes_ipv4" 3
  in
  impl ~packages ~connect "Qubesdb_ipv4.Make"
    (qubesdb @-> ethernet @-> arpv4 @-> ipv4)

let ipv4_qubes db ethernet arp = ipv4_qubes_conf $ db $ ethernet $ arp

let ipv6_conf ~ip ~gateway ~handle_ra ~no_init () =
  let packages_v = right_tcpip_library ~sublibs:[ "ipv6" ] "tcpip" in
  let runtime_args = Runtime_arg.[ v ip; v gateway; v handle_ra; v no_init ] in
  let connect _ modname = function
    | [ netif; etif; ip; gateway; handle_ra; no_init ] ->
        code ~pos:__POS__
          "%s.connect@[~no_init:%s@ ~handle_ra:%s@ ?cidr:%s@ ?gateway:%s@ %s@ \
           %s@]"
          modname no_init handle_ra ip gateway netif etif
    | _ -> connect_err "ipv6" 6
  in

  impl ~packages_v ~runtime_args ~connect "Ipv6.Make"
    (network @-> ethernet @-> ipv6)

let keyed_create_ipv6 ?group ?config ~no_init netif etif =
  let network, gateway =
    match config with
    | None -> (None, None)
    | Some { network; gateway } -> (Some network, gateway)
  in
  let ip = Runtime_arg.V6.network ?group network
  and gateway = Runtime_arg.V6.gateway ?group gateway
  and handle_ra = Runtime_arg.V6.accept_router_advertisements ?group () in
  ipv6_conf ~ip ~gateway ~handle_ra ~no_init () $ netif $ etif

let create_ipv6 ?group ?config netif etif =
  let network, gateway =
    match config with
    | None -> (None, None)
    | Some { network; gateway } -> (Some network, gateway)
  in
  let ip = Runtime_arg.V6.network ?group network
  and gateway = Runtime_arg.V6.gateway ?group gateway
  and handle_ra = Runtime_arg.V6.accept_router_advertisements ?group ()
  and no_init = Runtime_arg.ipv4_only ?group () in
  ipv6_conf ~ip ~gateway ~handle_ra ~no_init () $ netif $ etif

let ipv4v6_conf ~ipv4_only ~ipv6_only () =
  let packages_v = right_tcpip_library ~sublibs:[ "stack-direct" ] "tcpip" in
  let runtime_args = [ Runtime_arg.v ipv4_only; Runtime_arg.v ipv6_only ] in
  let connect _ modname = function
    | [ ipv4; ipv6; ipv4_only; ipv6_only ] ->
        code ~pos:__POS__ "%s.connect@[@ ~ipv4_only:%s@ ~ipv6_only:%s@ %s@ %s@]"
          modname ipv4_only ipv6_only ipv4 ipv6
    | _ -> connect_err "ipv4v6" 4
  in
  impl ~packages_v ~runtime_args ~connect "Tcpip_stack_direct.IPV4V6"
    (ipv4 @-> ipv6 @-> ipv4v6)

let keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 =
  ipv4v6_conf ~ipv4_only ~ipv6_only () $ ipv4 $ ipv6

let create_ipv4v6 ?group ipv4 ipv6 =
  let ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6
