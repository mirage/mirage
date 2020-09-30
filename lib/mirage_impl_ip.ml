module Key = Mirage_key
module Name = Functoria_app.Name
open Functoria
open Mirage_impl_arpv4
open Mirage_impl_ethernet
open Mirage_impl_mclock
open Mirage_impl_misc
open Mirage_impl_network
open Mirage_impl_qubesdb
open Mirage_impl_random
open Mirage_impl_time

type v4
type v6
type v4v6
type 'a ip = IP
type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip

let ip = Type IP
let ipv4: ipv4 typ = ip
let ipv6: ipv6 typ = ip
let ipv4v6: ipv4v6 typ = ip

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}
(** Types for IPv4 manual configuration. *)

let opt_opt_key s = Fmt.(option @@ prefix (unit ("?"^^s^^":")) pp_key)
let opt_map f = function Some x -> Some (f x) | None -> None
let (@?) x l = match x with Some s -> s :: l | None -> l
let (@??) x y = opt_map Key.abstract x @? y

(* convenience function for linking tcpip.unix for checksums *)
let right_tcpip_library ?ocamlfind ~sublibs pkg =
  let min = "5.0.0" and max = "6.0.0" in
  Key.match_ Key.(value target) @@ function
  | #Mirage_key.mode_unix ->
    [ package ~min ~max ?ocamlfind ~sublibs:("unix"::sublibs) pkg ]
  | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 ->
    [ package ~min ~max ?ocamlfind ~sublibs pkg ]

let ipv4_keyed_conf ~ip ?gateway () = impl @@ object
    inherit base_configurable
    method ty = random @-> mclock @-> ethernet @-> arpv4 @-> ipv4
    method name = Name.create "ipv4" ~prefix:"ipv4"
    method module_name = "Static_ipv4.Make"
    method! packages = right_tcpip_library ~sublibs:["ipv4"] "tcpip"
    method! keys = gateway @?? [Key.abstract ip]
    method! connect _ modname = function
    | [ _random ; _mclock ; etif ; arp ] ->
      Fmt.strf
        "%s.connect@[@ %a@ %a@ %s@ %s@]"
        modname
        Fmt.(prefix (unit "~cidr:") pp_key) ip
        (opt_opt_key "gateway") gateway
        etif arp
      | _ -> failwith (connect_err "ipv4 keyed" 4)
  end

let ipv4_dhcp_conf = impl @@ object
    inherit base_configurable
    method ty = random @-> mclock @-> time @-> network @-> ethernet @-> arpv4 @-> ipv4
    method name = Name.create "dhcp_ipv4" ~prefix:"dhcp_ipv4"
    method module_name = "Dhcp_ipv4.Make"
    method! packages =
      Key.pure [ package ~min:"1.3.0" ~max:"2.0.0" ~sublibs:["mirage"] "charrua-client" ]
    method! connect _ modname = function
      | [ _random ; _mclock ; _time ; network ; ethernet ; arp ] ->
        Fmt.strf "%s.connect@[@ %s@ %s@ %s@]"
          modname network ethernet arp
      | _ -> failwith (connect_err "ipv4 dhcp" 5)
  end

let ipv4_of_dhcp
    ?(random = default_random)
    ?(clock = default_monotonic_clock)
    ?(time = default_time)
    net ethif arp =
  ipv4_dhcp_conf $ random $ clock $ time $ net $ ethif $ arp

let create_ipv4 ?group ?config
    ?(random = default_random) ?(clock = default_monotonic_clock) etif arp =
  let network, gateway = match config with
    | None ->
      Ipaddr.V4.Prefix.of_string_exn "10.0.0.2/24", None
    | Some {network; gateway} -> network, gateway
  in
  let ip = Key.V4.network ?group network
  and gateway = Key.V4.gateway ?group gateway
  in
  ipv4_keyed_conf ~ip ~gateway () $ random $ clock $ etif $ arp

type ipv6_config = {
  network: Ipaddr.V6.Prefix.t;
  gateway: Ipaddr.V6.t option;
}
(** Types for IP manual configuration. *)

let ipv4_qubes_conf = impl @@ object
    inherit base_configurable
    method ty = qubesdb @-> random @-> mclock @-> ethernet @-> arpv4 @-> ipv4
    method name = Name.create "qubes_ipv4" ~prefix:"qubes_ipv4"
    method module_name = "Qubesdb_ipv4.Make"
    method! packages =
      Key.pure [ package ~min:"0.9.0" ~max:"0.10.0" "mirage-qubes-ipv4" ]
    method! connect _ modname = function
      | [  db ; _random ; _mclock ;etif; arp ] ->
        Fmt.strf "%s.connect@[@ %s@ %s@ %s@]" modname db etif arp
      | _ -> failwith (connect_err "qubes ipv4" 5)
  end

let ipv4_qubes
    ?(random = default_random)
    ?(clock = default_monotonic_clock) db ethernet arp =
  ipv4_qubes_conf $ db $ random $ clock $ ethernet $ arp

let ipv6_conf ?ip ?gateway () = impl @@ object
    inherit base_configurable
    method ty = network @-> ethernet @-> random @-> time @-> mclock @-> ipv6
    method name = Name.create "ipv6" ~prefix:"ipv6"
    method module_name = "Ipv6.Make"
    method! packages = right_tcpip_library ~sublibs:["ipv6"] "tcpip"
    method! keys = ip @?? gateway @?? []
    method! connect _ modname = function
      | [ interface ; etif ; _random ; _time ; _clock ] ->
        Fmt.strf "%s.connect@[@ %a@ %a@ %s@ %s@]"
          modname
          (opt_opt_key "cidr") ip
          (opt_opt_key "gateway") gateway
          interface
          etif
      | _ -> failwith (connect_err "ipv6" 5)
  end

let create_ipv6
    ?(random = default_random)
    ?(time = default_time)
    ?(clock = default_monotonic_clock)
    ?group ?config netif etif =
  let network, gateway = match config with
    | None -> None, None
    | Some { network ; gateway } -> Some network, gateway
  in
  let ip = Key.V6.network ?group network in
  let gateway = Key.V6.gateway ?group gateway in
  ipv6_conf ~ip ~gateway () $ netif $ etif $ random $ time $ clock

let ipv4v6_conf = impl @@ object
    inherit base_configurable
    method ty = ipv4 @-> ipv6 @-> ipv4v6
    method name = Name.create "ipv4v6" ~prefix:"ipv4v6"
    method module_name = "Tcpip_stack_direct.IPV4V6"
    method! packages = right_tcpip_library ~sublibs:["stack-direct"] "tcpip"
    method! connect _ modname = function
      | [ ipv4 ; ipv6 ] ->
        Fmt.strf "%s.connect@[@ %s@ %s@]"
          modname ipv4 ipv6
      | _ -> failwith (connect_err "ipv4v6" 2)
  end

let create_ipv4v6 ipv4 ipv6 = ipv4v6_conf $ ipv4 $ ipv6
