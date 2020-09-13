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
        Fmt.strf
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

let dhcp_ipv4_stack ?group ?(random = default_random) ?(clock = default_monotonic_clock) ?(time = default_time) ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = ipv4_of_dhcp ~random ~clock ~time tap e a in
  direct_stackv4 ?group tap e a i

let static_ipv4_stack ?group ?config ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = create_ipv4 ?group ?config e a in
  direct_stackv4 ?group tap e a i

let qubes_ipv4_stack ?group ?(qubesdb = default_qubesdb) ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = ipv4_qubes qubesdb e a in
  direct_stackv4 ?group tap e a i

let stackv4_socket_conf ?(group="") ips = impl @@ object
    inherit base_configurable
    method ty = stackv4
    val name = add_suffix "stackv4_socket" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_socket.V4"
    method! keys = [ Key.abstract ips ]
    method! packages = right_tcpip_library ~sublibs:["stack-socket"] "tcpip"
    method! deps = [abstract (socket_udpv4 None); abstract (socket_tcpv4 None)]
    method! connect _i modname = function
      | [ udpv4 ; tcpv4 ] ->
        Fmt.strf
          "%s.connect %a %s %s"
          modname pp_key ips udpv4 tcpv4
      | _ -> failwith (connect_err "socket stack" 2)
  end

let socket_stackv4 ?group ipv4s =
  stackv4_socket_conf ?group (Key.V4.ips ?group ipv4s)

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
    `Socket, socket_stackv4 ?group [Ipaddr.V4.any];
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
        Fmt.strf
          "%s.connect %s %s %s %s %s"
          modname interface ethif ip udp tcp
      | _ -> failwith (connect_err "direct stackv4" 9)
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

let static_ipv6_stack ?group ?(config = { addresses = [] ; netmasks = [] ; gateways = [] }) tap =
  let e = etif tap in
  let i = create_ipv6 ?group tap e config in
  direct_stackv6 ?group tap e i

let stackv6_socket_conf ?(group="") ips = impl @@ object
    inherit base_configurable
    method ty = stackv6
    val name = add_suffix "stackv6_socket" ~suffix:group
    method name = name
    method module_name = "Tcpip_stack_socket.V6"
    method! keys = [ Key.abstract ips ]
    method! packages = right_tcpip_library ~sublibs:["stack-socket"] "tcpip"
    method! deps = [abstract (socket_udpv4 None); abstract (socket_tcpv4 None)]
    method! connect _i modname = function
      | [ udp ; tcp ] ->
        Fmt.strf
          "%s.connect %a %s %s"
          modname pp_key ips udp tcp
      | _ -> failwith (connect_err "socket stack" 2)
  end

let socket_stackv6 ?group ips =
  stackv6_socket_conf ?group (Key.V6.ips ?group ips)

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
    `Socket, socket_stackv6 ?group [Ipaddr.V6.unspecified];
  ] ~default:(static_ipv6_stack ?group ?config tap)
