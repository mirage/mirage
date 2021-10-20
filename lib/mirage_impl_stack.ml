module Key = Mirage_key
open Functoria
open Mirage_impl_arpv4
open Mirage_impl_ethernet
open Mirage_impl_ip
open Mirage_impl_mclock
open Mirage_impl_misc
open Mirage_impl_network
open Mirage_impl_qubesdb
open Mirage_impl_random
open Mirage_impl_tcp
open Mirage_impl_time
open Mirage_impl_udp

type stackv4 = STACKV4
let stackv4 = Type STACKV4

let add_suffix s ~suffix = if suffix = "" then s else s^"_"^suffix

let stackv4_direct_conf ?(group="") () = impl @@ object
    inherit base_configurable
    method ty =
      time @-> random @-> network @->
      ethernet @-> arpv4 @-> ipv4 @-> Mirage_impl_icmp.icmpv4 @-> udpv4 @-> tcpv4 @->
      stackv4
    val name = add_suffix "stackv4_" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_direct.Make"
    method! packages = right_tcpip_library ~sublibs:["stack-direct"] "tcpip"
    method! connect _i modname = function
      | [ _t; _r; interface; ethif; arp; ip; icmp; udp; tcp ] ->
        Fmt.str
          "%s.connect %s %s %s %s %s %s %s"
          modname interface ethif arp ip icmp udp tcp
      | _ -> failwith (connect_err "direct stackv4" 9)
  end

let direct_stackv4
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time)
    ?group
    network eth arp ip =
  stackv4_direct_conf ?group ()
  $ time $ random $ network
  $ eth $ arp $ ip
  $ Mirage_impl_icmp.direct_icmpv4 ip
  $ direct_udp ~random ip
  $ direct_tcp ~clock ~random ~time ip

let dhcp_ipv4 ?random ?clock ?time tap e a =
  ipv4_of_dhcp ?random ?clock ?time tap e a

let dhcp_ipv4_stack ?group ?(random = default_random) ?(clock = default_monotonic_clock) ?(time = default_time) ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = dhcp_ipv4 ~random ~clock ~time tap e a in
  direct_stackv4 ?group tap e a i

let static_ipv4 ?group ?config ?no_init e a =
  create_ipv4 ?group ?config ?no_init e a

let static_ipv4_stack ?group ?config ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = static_ipv4 ?group ?config e a in
  direct_stackv4 ?group tap e a i

let qubes_ipv4 ?(qubesdb = default_qubesdb) e a =
  ipv4_qubes qubesdb e a

let qubes_ipv4_stack ?group ?(qubesdb = default_qubesdb) ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = qubes_ipv4 ~qubesdb e a in
  direct_stackv4 ?group tap e a i

let socket_stackv4 ?(group="") () = impl @@ object
    inherit base_configurable
    method ty = stackv4
    val name = add_suffix "stackv4_socket" ~suffix:group
    val key = Key.V4.network ~group Ipaddr.V4.Prefix.global
    method name = name
    method module_name = "Tcpip_stack_socket.V4"
    method! packages = right_tcpip_library ~sublibs:["stack-socket"] "tcpip"
    method! deps = [abstract (keyed_socket_udpv4 key) ; abstract (keyed_socket_tcpv4 key)]
    method! connect _i modname = function
      | [ udpv4 ; tcpv4 ] -> Fmt.str "%s.connect %s %s" modname udpv4 tcpv4
      | _ -> failwith (connect_err "socket stack" 2)
  end

(** Generic stack *)

let generic_stackv4
    ?group ?config
    ?(dhcp_key = Key.value @@ Key.dhcp ?group ())
    ?(net_key = Key.value @@ Key.net ?group ())
    (tap : network impl) : stackv4 impl =
  let choose target net dhcp =
    match target, net, dhcp with
    | `Qubes, _, _ -> `Qubes
    | _, Some `Socket, _ -> `Socket
    | _, _, true -> `Dhcp
    | (`Unix | `MacOSX), None, false -> `Socket
    | _, _, _ -> `Static
  in
  let p = Functoria_key.((pure choose)
          $ Key.(value target)
          $ net_key
          $ dhcp_key) in
  match_impl p [
    `Dhcp, dhcp_ipv4_stack ?group tap;
    `Socket, socket_stackv4 ?group ();
    `Qubes, qubes_ipv4_stack ?group tap;
  ] ~default:(static_ipv4_stack ?config ?group tap)

(** IPv6 *)
type stackv6 = STACKV6
let stackv6 = Type STACKV6

let stackv6_direct_conf ?(group="") () = impl @@ object
    inherit base_configurable
    method ty =
      time @-> random @-> network @->
      ethernet @-> ipv6 @-> udpv6 @-> tcpv6 @->
      stackv6
    val name = add_suffix "stackv6_" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_direct.MakeV6"
    method! packages = right_tcpip_library ~sublibs:["stack-direct"] "tcpip"
    method! connect _i modname = function
      | [ _t; _r; interface; ethif; ip; udp; tcp ] ->
        Fmt.str
          "%s.connect %s %s %s %s %s"
          modname interface ethif ip udp tcp
      | _ -> failwith (connect_err "direct stackv6" 7)
  end

let direct_stackv6
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time)
    ?group
    network eth ip =
  stackv6_direct_conf ?group ()
  $ time $ random $ network
  $ eth $ ip
  $ direct_udp ~random ip
  $ direct_tcp ~clock ~random ~time ip

let static_ipv6_stack ?group ?config tap =
  let e = etif tap in
  let i = create_ipv6 ?group ?config tap e in
  direct_stackv6 ?group tap e i

let socket_stackv6 ?(group="") () = impl @@ object
    inherit base_configurable
    method ty = stackv6
    val name = add_suffix "stackv6_socket" ~suffix:group
    val key = Key.V6.network ~group None
    method name = name
    method module_name = "Tcpip_stack_socket.V6"
    method! packages = right_tcpip_library ~sublibs:["stack-socket"] "tcpip"
    method! deps = [abstract (keyed_socket_udpv6 key); abstract (keyed_socket_tcpv6 key)]
    method! connect _i modname = function
      | [ udp ; tcp ] -> Fmt.str "%s.connect %s %s" modname udp tcp
      | _ -> failwith (connect_err "socket stack" 2)
  end

(** Generic stack *)

let generic_stackv6
    ?group ?config
    ?(net_key = Key.value @@ Key.net ?group ())
    (tap : network impl) : stackv6 impl =
  let choose target net =
    match target, net with
    | _, Some `Socket -> `Socket
    | (`Unix | `MacOSX), None -> `Socket
    | _, _ -> `Static
  in
  let p = Functoria_key.((pure choose)
          $ Key.(value target)
          $ net_key) in
  match_impl p [
    `Socket, socket_stackv6 ?group ();
  ] ~default:(static_ipv6_stack ?group ?config tap)

(** dual stack *)

type stackv4v6 = STACKV4V6
let stackv4v6 = Type STACKV4V6

let stackv4v6_direct_conf ?(group="") () = impl @@ object
    inherit base_configurable
    method ty =
      time @-> random @-> network @->
      ethernet @-> arpv4 @-> ipv4v6 @-> Mirage_impl_icmp.icmpv4 @->
      udp @-> tcp @->
      stackv4v6
    val name = add_suffix "stack_" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_direct.MakeV4V6"
    method! packages = right_tcpip_library ~sublibs:["stack-direct"] "tcpip"
    method! connect _i modname = function
      | [ _t; _r; interface; ethif; arp; ipv4v6; icmpv4; udp; tcp ] ->
        Fmt.str
          "%s.connect %s %s %s %s %s %s %s"
          modname interface ethif arp ipv4v6 icmpv4 udp tcp
      | _ -> failwith (connect_err "direct stack" 8)
  end

let direct_stackv4v6
    ?(clock=default_monotonic_clock)
    ?(random=default_random)
    ?(time=default_time)
    ?group ~ipv4_only ~ipv6_only
    network eth arp ipv4 ipv6 =
  let ip = keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 in
  stackv4v6_direct_conf ?group ()
  $ time $ random $ network
  $ eth $ arp $ ip $ Mirage_impl_icmp.direct_icmpv4 ipv4
  $ direct_udp ~random ip
  $ direct_tcp ~clock ~random ~time ip

let static_ipv4v6_stack
    ?group
    ?ipv6_config
    ?ipv4_config
    ?(arp = arp ?time:None)
    tap
  =
  let ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group ()
  in
  let e = etif tap in
  let a = arp e in
  let i4 = static_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only e a in
  let i6 = create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only tap e in
  direct_stackv4v6 ?group ~ipv4_only ~ipv6_only tap e a i4 i6

let generic_ipv4v6_stack
    p
    ?group
    ?ipv6_config
    ?ipv4_config
    ?(arp = arp ?time:None)
    tap
  =
  let ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group ()
  in
  let e = etif tap in
  let a = arp e in
  let i4 =
    match_impl p
    [ `Qubes, qubes_ipv4 e a;
      `Dhcp, dhcp_ipv4 tap e a ]
    ~default:(static_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only e a)
  in
  let i6 = create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only tap e in
  direct_stackv4v6 ?group ~ipv4_only ~ipv6_only tap e a i4 i6

let socket_stackv4v6 ?(group="") () = impl @@ object
    inherit base_configurable
    method ty = stackv4v6
    val name = add_suffix "stackv4v6_socket" ~suffix:group
    val v4key = Key.V4.network ~group Ipaddr.V4.Prefix.global
    val v6key = Key.V6.network ~group None
    val ipv4_only = Key.ipv4_only ~group ()
    val ipv6_only = Key.ipv6_only ~group ()
    method name = name
    method module_name = "Tcpip_stack_socket.V4V6"
    method! packages = right_tcpip_library ~sublibs:["stack-socket"] "tcpip"
    method! deps = [
      abstract (keyed_socket_udpv4v6 ~ipv4_only ~ipv6_only v4key v6key);
      abstract (keyed_socket_tcpv4v6 ~ipv4_only ~ipv6_only v4key v6key)
    ]
    method! connect _i modname = function
      | [ udp ; tcp ] -> Fmt.str "%s.connect %s %s" modname udp tcp
      | _ -> failwith (connect_err "socket stack" 2)
  end

(** Generic stack *)
let generic_stackv4v6
    ?group ?ipv6_config ?ipv4_config
    ?(dhcp_key = Key.value @@ Key.dhcp ?group ())
    ?(net_key = Key.value @@ Key.net ?group ())
    (tap : network impl) : stackv4v6 impl =
  let choose target net dhcp =
    match target, net, dhcp with
    | `Qubes, _, _ -> `Qubes
    | _, Some `Socket, _ -> `Socket
    | _, _, true -> `Dhcp
    | (`Unix | `MacOSX), None, false -> `Socket
    | _, _, _ -> `Static
  in
  let p = Functoria_key.((pure choose)
          $ Key.(value target)
          $ net_key
          $ dhcp_key) in
  match_impl p [
    `Socket, socket_stackv4v6 ?group ();
  ] ~default:(generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config tap)
