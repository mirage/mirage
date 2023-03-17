open Functoria
open Mirage_impl_arpv4
open Mirage_impl_ethernet
open Mirage_impl_mclock
open Mirage_impl_misc
open Mirage_impl_network
open Mirage_impl_qubesdb
open Mirage_impl_random
open Mirage_impl_time
module Key = Mirage_key

type v4
type v6
type v4v6
type 'a ip = IP
type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip

let ip = Type.Type IP
let ipv4 : ipv4 typ = ip
let ipv6 : ipv6 typ = ip
let ipv4v6 : ipv4v6 typ = ip

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}
(** Types for IPv4 manual configuration. *)

let opt_opt_key s = Fmt.(option @@ (any ("?" ^^ s ^^ ":") ++ pp_key))
let opt_key s = Fmt.(option @@ (any ("~" ^^ s ^^ ":") ++ pp_key))
let opt_map f = function Some x -> Some (f x) | None -> None
let ( @? ) x l = match x with Some s -> s :: l | None -> l
let ( @?? ) x y = opt_map Key.v x @? y

(* convenience function for linking tcpip.unix for checksums *)
let right_tcpip_library ?libs ~sublibs pkg =
  let min = "7.0.0" and max = "9.0.0" in
  Key.pure [ package ~min ~max ?libs ~sublibs pkg ]

let ipv4_keyed_conf ~ip ?gateway ?no_init () =
  let packages_v = right_tcpip_library ~sublibs:[ "ipv4" ] "tcpip" in
  let keys = no_init @?? gateway @?? [ Key.v ip ] in
  let connect _ modname = function
    | [ _random; _mclock; etif; arp ] ->
        Fmt.str "%s.connect@[@ %a@ %a@ %a@ %s@ %s@]" modname (opt_key "no_init")
          no_init
          Fmt.(any "~cidr:" ++ pp_key)
          ip (opt_opt_key "gateway") gateway etif arp
    | _ -> failwith (connect_err "ipv4 keyed" 4)
  in
  impl ~packages_v ~keys ~connect "Static_ipv4.Make"
    (random @-> mclock @-> ethernet @-> arpv4 @-> ipv4)

let ipv4_dhcp_conf =
  let packages =
    [ package ~min:"1.3.0" ~max:"2.0.0" ~sublibs:[ "mirage" ] "charrua-client" ]
  in
  let connect _ modname = function
    | [ _random; _mclock; _time; network; ethernet; arp ] ->
        Fmt.str "%s.connect@[@ %s@ %s@ %s@]" modname network ethernet arp
    | _ -> failwith (connect_err "ipv4 dhcp" 5)
  in
  impl ~packages ~connect "Dhcp_ipv4.Make"
    (random @-> mclock @-> time @-> network @-> ethernet @-> arpv4 @-> ipv4)

let ipv4_of_dhcp ?(random = default_random) ?(clock = default_monotonic_clock)
    ?(time = default_time) net ethif arp =
  ipv4_dhcp_conf $ random $ clock $ time $ net $ ethif $ arp

let create_ipv4 ?group ?config ?no_init ?(random = default_random)
    ?(clock = default_monotonic_clock) etif arp =
  let network, gateway =
    match config with
    | None -> (Ipaddr.V4.Prefix.of_string_exn "10.0.0.2/24", None)
    | Some { network; gateway } -> (network, gateway)
  in
  let ip = Key.V4.network ?group network
  and gateway = Key.V4.gateway ?group gateway in
  ipv4_keyed_conf ~ip ~gateway ?no_init () $ random $ clock $ etif $ arp

type ipv6_config = {
  network : Ipaddr.V6.Prefix.t;
  gateway : Ipaddr.V6.t option;
}
(** Types for IP manual configuration. *)

let ipv4_qubes_conf =
  let packages = [ package ~min:"0.9.0" ~max:"0.10.0" "mirage-qubes-ipv4" ] in
  let connect _ modname = function
    | [ db; _random; _mclock; etif; arp ] ->
        Fmt.str "%s.connect@[@ %s@ %s@ %s@]" modname db etif arp
    | _ -> failwith (connect_err "qubes ipv4" 5)
  in
  impl ~packages ~connect "Qubesdb_ipv4.Make"
    (qubesdb @-> random @-> mclock @-> ethernet @-> arpv4 @-> ipv4)

let ipv4_qubes ?(random = default_random) ?(clock = default_monotonic_clock) db
    ethernet arp =
  ipv4_qubes_conf $ db $ random $ clock $ ethernet $ arp

let ipv6_conf ?ip ?gateway ?handle_ra ?no_init () =
  let packages_v = right_tcpip_library ~sublibs:[ "ipv6" ] "tcpip" in
  let keys = ip @?? gateway @?? handle_ra @?? no_init @?? [] in
  let connect _ modname = function
    | [ netif; etif; _random; _time; _clock ] ->
        Fmt.str "%s.connect@[@ %a@ %a@ %a@ %a@ %s@ %s@]" modname
          (opt_key "no_init") no_init (opt_key "handle_ra") handle_ra
          (opt_opt_key "cidr") ip (opt_opt_key "gateway") gateway netif etif
    | _ -> failwith (connect_err "ipv6" 5)
  in
  impl ~packages_v ~keys ~connect "Ipv6.Make"
    (network @-> ethernet @-> random @-> time @-> mclock @-> ipv6)

let create_ipv6 ?(random = default_random) ?(time = default_time)
    ?(clock = default_monotonic_clock) ?group ?config ?no_init netif etif =
  let network, gateway =
    match config with
    | None -> (None, None)
    | Some { network; gateway } -> (Some network, gateway)
  in
  let ip = Key.V6.network ?group network
  and gateway = Key.V6.gateway ?group gateway
  and handle_ra = Key.V6.accept_router_advertisements ?group () in
  ipv6_conf ~ip ~gateway ~handle_ra ?no_init ()
  $ netif
  $ etif
  $ random
  $ time
  $ clock

let ipv4v6_conf ?ipv4_only ?ipv6_only () =
  let packages_v = right_tcpip_library ~sublibs:[ "stack-direct" ] "tcpip" in
  let keys = ipv4_only @?? ipv6_only @?? [] in
  let connect _ modname = function
    | [ ipv4; ipv6 ] ->
        Fmt.str "%s.connect@[@ %a@ %a@ %s@ %s@]" modname (opt_key "ipv4_only")
          ipv4_only (opt_key "ipv6_only") ipv6_only ipv4 ipv6
    | _ -> failwith (connect_err "ipv4v6" 2)
  in
  impl ~packages_v ~keys ~connect "Tcpip_stack_direct.IPV4V6"
    (ipv4 @-> ipv6 @-> ipv4v6)

let keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 =
  ipv4v6_conf ~ipv4_only ~ipv6_only () $ ipv4 $ ipv6

let create_ipv4v6 ?group ipv4 ipv6 =
  let ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group () in
  keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6
