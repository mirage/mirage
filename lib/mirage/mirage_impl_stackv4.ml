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

type stackv4 = STACKV4

let stackv4 = Type.v STACKV4

let stackv4_direct_conf () =
  let packages_v = right_tcpip_library ~sublibs:[ "stack-direct" ] "tcpip" in
  let connect _i modname = function
    | [ _t; _r; interface; ethif; arp; ip; icmp; udp; tcp ] ->
        Fmt.strf "%s.connect %s %s %s %s %s %s %s" modname interface ethif arp
          ip icmp udp tcp
    | _ -> failwith (connect_err "direct stackv4" 9)
  in
  impl ~packages_v ~connect "Tcpip_stack_direct.Make"
    ( time
    @-> random
    @-> network
    @-> ethernet
    @-> arpv4
    @-> ipv4
    @-> Mirage_impl_icmp.icmpv4
    @-> udpv4
    @-> tcpv4
    @-> stackv4 )

let direct_stackv4 ?(clock = default_monotonic_clock) ?(random = default_random)
    ?(time = default_time) network eth arp ip =
  stackv4_direct_conf ()
  $ time
  $ random
  $ network
  $ eth
  $ arp
  $ ip
  $ Mirage_impl_icmp.direct_icmpv4 ip
  $ direct_udp ~random ip
  $ direct_tcp ~clock ~random ~time ip

let dhcp_ipv4_stack ?(random = default_random) ?(time = default_time)
    ?(arp = arp ?time:None) tap =
  let config = dhcp random time tap in
  let e = etif tap in
  let a = arp e in
  let i = ipv4_of_dhcp config e a in
  direct_stackv4 tap e a i

let static_ipv4_stack ?group ?config ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = create_ipv4 ?group ?config e a in
  direct_stackv4 tap e a i

let qubes_ipv4_stack ?(qubesdb = default_qubesdb) ?(arp = arp ?time:None) tap =
  let e = etif tap in
  let a = arp e in
  let i = ipv4_qubes qubesdb e a in
  direct_stackv4 tap e a i

let stackv4_socket_conf ips =
  let keys = [ Key.v ips ] in
  let packages_v = right_tcpip_library ~sublibs:[ "stack-socket" ] "tcpip" in
  let extra_deps =
    [ abstract (socket_udpv4 None); abstract (socket_tcpv4 None) ]
  in
  let connect _i modname = function
    | [ udpv4; tcpv4 ] ->
        Fmt.strf "%s.connect %a %s %s" modname pp_key ips udpv4 tcpv4
    | _ -> failwith (connect_err "socket stack" 2)
  in
  impl ~keys ~packages_v ~extra_deps ~connect "Tcpip_stack_socket" stackv4

let socket_stackv4 ?group ipv4s = stackv4_socket_conf (Key.V4.ips ?group ipv4s)

(** Generic stack *)

let generic_stackv4 ?group ?config ?(dhcp_key = Key.value @@ Key.dhcp ?group ())
    ?(net_key = Key.value @@ Key.net ?group ()) (tap : network impl) :
    stackv4 impl =
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
    [
      (`Dhcp, dhcp_ipv4_stack tap);
      (`Socket, socket_stackv4 ?group [ Ipaddr.V4.any ]);
      (`Qubes, qubes_ipv4_stack tap);
    ]
    ~default:(static_ipv4_stack ?config ?group tap)
