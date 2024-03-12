open Functoria

type stackv4v6

val stackv4v6 : stackv4v6 typ

val direct_stackv4v6 :
  ?mclock:Mclock.mclock impl ->
  ?random:Random.random impl ->
  ?time:Time.time impl ->
  ?tcp:Tcp.tcpv4v6 impl ->
  ipv4_only:bool runtime_arg ->
  ipv6_only:bool runtime_arg ->
  Network.network impl ->
  Ethernet.ethernet impl ->
  Arp.arpv4 impl ->
  Ip.ipv4 impl ->
  Ip.ipv6 impl ->
  stackv4v6 impl

val socket_stackv4v6 : ?group:string -> unit -> stackv4v6 impl

val static_ipv4v6_stack :
  ?group:string ->
  ?ipv6_config:Ip.ipv6_config ->
  ?ipv4_config:Ip.ipv4_config ->
  ?arp:(Ethernet.ethernet impl -> Arp.arpv4 impl) ->
  ?tcp:Tcp.tcpv4v6 impl ->
  Network.network impl ->
  stackv4v6 impl

val generic_stackv4v6 :
  ?group:string ->
  ?ipv6_config:Ip.ipv6_config ->
  ?ipv4_config:Ip.ipv4_config ->
  ?dhcp_key:bool value ->
  ?net_key:[ `Direct | `Socket ] option value ->
  ?tcp:Tcp.tcpv4v6 impl ->
  Network.network impl ->
  stackv4v6 impl
