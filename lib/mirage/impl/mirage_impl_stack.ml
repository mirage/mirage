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
module Key = Mirage_key

let dhcp_ipv4 ?random ?clock ?time tap e a =
  ipv4_of_dhcp ?random ?clock ?time tap e a

let static_ipv4 ?group ?config ?no_init e a =
  create_ipv4 ?group ?config ?no_init e a

let qubes_ipv4 ?(qubesdb = default_qubesdb) e a = ipv4_qubes qubesdb e a

(** dual stack *)

type stackv4v6 = STACKV4V6

let stackv4v6 = Type.v STACKV4V6

let stackv4v6_direct_conf () =
  let packages_v = right_tcpip_library ~sublibs:[ "stack-direct" ] "tcpip" in
  let connect _i modname = function
    | [ _t; _r; interface; ethif; arp; ipv4v6; icmpv4; udp; tcp ] ->
        Fmt.str "%s.connect %s %s %s %s %s %s %s" modname interface ethif arp
          ipv4v6 icmpv4 udp tcp
    | _ -> failwith (connect_err "direct stack" 8)
  in
  impl ~packages_v ~connect "Tcpip_stack_direct.MakeV4V6"
    (time
    @-> random
    @-> network
    @-> ethernet
    @-> arpv4
    @-> ipv4v6
    @-> Mirage_impl_icmp.icmpv4
    @-> udp
    @-> tcp
    @-> stackv4v6)

let direct_stackv4v6 ?(mclock = default_monotonic_clock)
    ?(random = default_random) ?(time = default_time) ?tcp ~ipv4_only ~ipv6_only
    network eth arp ipv4 ipv6 =
  let ip = keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 in
  stackv4v6_direct_conf ()
  $ time
  $ random
  $ network
  $ eth
  $ arp
  $ ip
  $ Mirage_impl_icmp.direct_icmpv4 ipv4
  $ direct_udp ~random ip
  $
  match tcp with None -> direct_tcp ~mclock ~random ~time ip | Some tcp -> tcp

let static_ipv4v6_stack ?group ?ipv6_config ?ipv4_config ?(arp = arp ?time:None)
    ?tcp tap =
  let ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group () in
  let e = etif tap in
  let a = arp e in
  let i4 = create_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only e a in
  let i6 = create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only tap e in
  direct_stackv4v6 ~ipv4_only ~ipv6_only ?tcp tap e a i4 i6

let generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config
    ?(arp = arp ?time:None) ?tcp tap =
  let ipv4_only = Key.ipv4_only ?group ()
  and ipv6_only = Key.ipv6_only ?group () in
  let e = etif tap in
  let a = arp e in
  let i4 =
    match_impl p
      [ (`Qubes, qubes_ipv4 e a); (`Dhcp, dhcp_ipv4 tap e a) ]
      ~default:(static_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only e a)
  in
  let i6 = create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only tap e in
  direct_stackv4v6 ~ipv4_only ~ipv6_only ?tcp tap e a i4 i6

let socket_stackv4v6 ?(group = "") () =
  let v4key = Key.V4.network ~group Ipaddr.V4.Prefix.global in
  let v6key = Key.V6.network ~group None in
  let ipv4_only = Key.ipv4_only ~group () in
  let ipv6_only = Key.ipv6_only ~group () in
  let packages_v = right_tcpip_library ~sublibs:[ "stack-socket" ] "tcpip" in
  let extra_deps =
    [
      dep (udpv4v6_socket_conf ~ipv4_only ~ipv6_only v4key v6key);
      dep (tcpv4v6_socket_conf ~ipv4_only ~ipv6_only v4key v6key);
    ]
  in
  let connect _i modname = function
    | [ udp; tcp ] -> Fmt.str "%s.connect %s %s" modname udp tcp
    | _ -> failwith (connect_err "socket stack" 2)
  in
  impl ~packages_v ~extra_deps ~connect "Tcpip_stack_socket.V4V6" stackv4v6

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
  match_impl p
    [ (`Socket, socket_stackv4v6 ?group ()) ]
    ~default:(generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config ?tcp tap)
