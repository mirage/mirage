open Functoria

type stackv4v6

val stackv4v6 : stackv4v6 typ

val direct_stackv4v6 :
  ?mclock:Mirage_impl_mclock.mclock impl ->
  ?random:Mirage_impl_random.random impl ->
  ?time:Mirage_impl_time.time impl ->
  ?tcp:Mirage_impl_tcp.tcpv4v6 impl ->
  ipv4_only:bool runtime_key ->
  ipv6_only:bool runtime_key ->
  Mirage_impl_network.network impl ->
  Mirage_impl_ethernet.ethernet impl ->
  Mirage_impl_arpv4.arpv4 impl ->
  Mirage_impl_ip.ipv4 impl ->
  Mirage_impl_ip.ipv6 impl ->
  stackv4v6 impl

val socket_stackv4v6 : ?group:string -> unit -> stackv4v6 impl

val static_ipv4v6_stack :
  ?group:string ->
  ?ipv6_config:Mirage_impl_ip.ipv6_config ->
  ?ipv4_config:Mirage_impl_ip.ipv4_config ->
  ?arp:(Mirage_impl_ethernet.ethernet impl -> Mirage_impl_arpv4.arpv4 impl) ->
  ?tcp:Mirage_impl_tcp.tcpv4v6 impl ->
  Mirage_impl_network.network impl ->
  stackv4v6 impl

val generic_stackv4v6 :
  ?group:string ->
  ?ipv6_config:Mirage_impl_ip.ipv6_config ->
  ?ipv4_config:Mirage_impl_ip.ipv4_config ->
  ?dhcp_key:bool value ->
  ?net_key:[ `Direct | `Socket ] option value ->
  ?tcp:Mirage_impl_tcp.tcpv4v6 impl ->
  Mirage_impl_network.network impl ->
  stackv4v6 impl
