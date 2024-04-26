open Functoria.DSL
open Arp
open Ethernet
open Ip
open Mclock
open Misc
open Network
open Qubesdb
open Random
open Tcp
open Time
open Udp

let dhcp_ipv4 ?random ?clock ?time tap e a =
  ipv4_of_dhcp ?random ?clock ?time tap e a

let qubes_ipv4 ?(qubesdb = default_qubesdb) e a = ipv4_qubes qubesdb e a

(** dual stack *)

type stackv4v6 = STACKV4V6

let stackv4v6 = typ STACKV4V6

let stackv4v6_direct_conf time random network ethernet arpv4 ipv4v6 icmpv4 udp tcp =
  let packages_v =
    Key.pure (right_tcpip_library ~sublibs:[ "stack" ; "stack-direct" ] "tcpip")
  in
  let connect _i modname = function
    | [ _t; _r; interface; ethif; arp; ipv4v6; icmpv4; udp; tcp ] ->
        code ~pos:__POS__ "%s.connect ~netif:%s ~ethernet:%s ~arp:%s ~ip:%s ~icmp:%s ~udp:%s ~tcp:%s ()" modname interface
          ethif arp ipv4v6 icmpv4 udp tcp
    | _ -> connect_err "direct stack" 9
  in
  let extra_deps = [ dep time ; dep random ; dep network ; dep ethernet ;
                     dep arpv4 ; dep ipv4v6 ; dep icmpv4 ; dep udp ; dep tcp ]
  in
  impl ~extra_deps ~packages_v ~connect "Tcpip_stack" stackv4v6

let socket_stackv4v6 ipv4v6 udp tcp =
  let packages_v =
    Key.pure (right_tcpip_library ~sublibs:[ "stack" ; "stack-unix" ] "tcpip")
  in
  let connect _i modname = function
    | [ ipv4v6; udp; tcp ] ->
        code ~pos:__POS__ "%s.connect ~ip:%s ~udp:%s ~tcp:%s ()" modname
          ipv4v6 udp tcp
    | _ -> connect_err "direct stack" 9
  in
  let extra_deps = [ dep ipv4v6 ; dep udp ; dep tcp ]
  in
  impl ~extra_deps ~packages_v ~connect "Tcpip_stack" stackv4v6

let direct_stackv4v6 p ?(mclock = default_monotonic_clock)
    ?(random = default_random) ?(time = default_time) ?tcp ~ipv4_only ~ipv6_only
    network eth arp ipv4 ipv6 =
  let ip = keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 in
  let udp = udp_impl ip in
  let tcp =
    match tcp with None -> tcp_impl ~mclock ~random ~time ip | Some tcp -> tcp
  in
  match_impl p
    [ (`Socket, socket_stackv4v6 ip udp tcp)]
    ~default:(stackv4v6_direct_conf time random network eth arp ip (Icmp.icmpv4_impl ipv4) udp tcp)

let static_ipv4v6_stack ?group ?ipv6_config ?ipv4_config ?(arp = arp)
    ?tcp tap =
  let ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  let ethif = etif tap in
  let arp = arp ethif in
  let i4 = create_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only ~ethif ~arp () in
  let i6 = create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only ~netif:tap ~ethif () in
  let choose target =
    match target with
    | (`Unix | `MacOSX) -> `Socket
    | _ -> `Static
  in
  let p = Key.(pure choose $ Key.(value target)) in
  direct_stackv4v6 p ~ipv4_only ~ipv6_only ?tcp tap ethif arp i4 i6

let generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config
    ?(arp = arp) ?tcp tap =
  let ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  let ethif = etif tap in
  let arp = arp ethif in
  let i4 =
    match_impl p
      [ (`Qubes, qubes_ipv4 ethif arp); (`Dhcp, dhcp_ipv4 tap ethif arp) ]
      ~default:(create_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only ~ethif ~arp ())
  in
  let i6 = create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only ~netif:tap ~ethif () in
  direct_stackv4v6 p ~ipv4_only ~ipv6_only ?tcp tap ethif arp i4 i6

(** Generic stack *)
let generic_stackv4v6 ?group ?ipv6_config ?ipv4_config
    ?(dhcp_key = Key.value @@ Key.dhcp ?group ())
    ?(net_key = Key.value @@ Key.net ?group ()) ?tcp (tap : network impl) :
    stackv4v6 impl =
  let choose target net dhcp =
    match (target, net, dhcp) with
    | `Qubes, _, _ -> `Qubes
    | _, Some `Socket, _ -> `Socket
    | _, _, true -> `Dhcp
    | (`Unix | `MacOSX), None, false -> `Socket
    | _, _, _ -> `Static
  in
  let p = Key.(pure choose $ Key.(value target) $ net_key $ dhcp_key) in
  generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config ?tcp tap
