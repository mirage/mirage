open Functoria.DSL
open Arp
open Ethernet
open Ip
open Misc
open Network
open Qubesdb
open Tcp
open Udp

let dhcp_ipv4 tap e a = ipv4_of_dhcp tap e a

let static_ipv4 ?group ?config ~no_init e a =
  keyed_create_ipv4 ?group ?config ~no_init e a

let qubes_ipv4 ?(qubesdb = default_qubesdb) e a = ipv4_qubes qubesdb e a

(** dual stack *)

type stackv4v6 = STACKV4V6

let stackv4v6 = typ STACKV4V6

let stackv4v6_direct_conf () =
  let packages_v = right_tcpip_library ~sublibs:[ "stack-direct" ] "tcpip" in
  let connect _i modname = function
    | [ interface; ethif; arp; ipv4v6; icmpv4; udp; tcp ] ->
        code ~pos:__POS__ "%s.connect %s %s %s %s %s %s %s" modname interface
          ethif arp ipv4v6 icmpv4 udp tcp
    | _ -> connect_err "direct stack" 7
  in
  impl ~packages_v ~connect "Tcpip_stack_direct.MakeV4V6"
    (network
    @-> ethernet
    @-> arpv4
    @-> ipv4v6
    @-> Icmp.icmpv4
    @-> udp
    @-> tcp
    @-> stackv4v6)

let direct_stackv4v6 ?group ?tcp network eth arp ipv4 ipv6 =
  let ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  let ip = keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 in
  stackv4v6_direct_conf ()
  $ network
  $ eth
  $ arp
  $ ip
  $ Icmp.direct_icmpv4 ipv4
  $ direct_udp ip
  $ match tcp with None -> direct_tcp ip | Some tcp -> tcp

let keyed_direct_stackv4v6 ?tcp ~ipv4_only ~ipv6_only network eth arp ipv4 ipv6
    =
  let ip = keyed_ipv4v6 ~ipv4_only ~ipv6_only ipv4 ipv6 in
  stackv4v6_direct_conf ()
  $ network
  $ eth
  $ arp
  $ ip
  $ Icmp.direct_icmpv4 ipv4
  $ direct_udp ip
  $ match tcp with None -> direct_tcp ip | Some tcp -> tcp

let static_ipv4v6_stack ?group ?ipv6_config ?ipv4_config ?(arp = arp) ?tcp tap =
  let ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  let e = ethif tap in
  let a = arp e in
  let i4 = create_ipv4 ?group ?config:ipv4_config e a in
  let i6 = create_ipv6 ?group ?config:ipv6_config tap e in
  keyed_direct_stackv4v6 ~ipv4_only ~ipv6_only ?tcp tap e a i4 i6

let generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config ?(arp = arp) ?tcp
    tap =
  let ipv4_only = Runtime_arg.ipv4_only ?group ()
  and ipv6_only = Runtime_arg.ipv6_only ?group () in
  let e = ethif tap in
  let a = arp e in
  let i4 =
    match_impl p
      [ (`Qubes, qubes_ipv4 e a); (`Dhcp, dhcp_ipv4 tap e a) ]
      ~default:(static_ipv4 ?group ?config:ipv4_config ~no_init:ipv6_only e a)
  in
  let i6 =
    keyed_create_ipv6 ?group ?config:ipv6_config ~no_init:ipv4_only tap e
  in
  keyed_direct_stackv4v6 ~ipv4_only ~ipv6_only ?tcp tap e a i4 i6

let socket_stackv4v6 ?(group = "") () =
  let v4key = Runtime_arg.V4.network ~group Ipaddr.V4.Prefix.global in
  let v6key = Runtime_arg.V6.network ~group None in
  let ipv4_only = Runtime_arg.ipv4_only ~group () in
  let ipv6_only = Runtime_arg.ipv6_only ~group () in
  let packages_v = right_tcpip_library ~sublibs:[ "stack-socket" ] "tcpip" in
  let extra_deps =
    [
      dep (udpv4v6_socket_conf ~ipv4_only ~ipv6_only v4key v6key);
      dep (tcpv4v6_socket_conf ~ipv4_only ~ipv6_only v4key v6key);
    ]
  in
  let connect _i modname = function
    | [ udp; tcp ] -> code ~pos:__POS__ "%s.connect %s %s" modname udp tcp
    | _ -> connect_err "socket_stackv4v6" 2
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
    | _, Some `Host, _ -> `Socket
    | _, _, true -> `Dhcp
    | (`Unix | `MacOSX), None, false -> `Socket
    | _, _, _ -> `Static
  in
  let p = Key.(pure choose $ Key.(value target) $ net_key $ dhcp_key) in
  match_impl p
    [ (`Socket, socket_stackv4v6 ?group ()) ]
    ~default:(generic_ipv4v6_stack p ?group ?ipv6_config ?ipv4_config ?tcp tap)
