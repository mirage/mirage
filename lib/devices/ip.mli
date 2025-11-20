open Functoria.DSL

type v4
type v6
type v4v6
type 'a ip
type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip

val ip : 'a ip typ
val ipv4 : ipv4 typ
val ipv6 : ipv6 typ
val ipv4v6 : ipv4v6 typ

val create_ipv4 :
  ?group:string -> Ethernet.ethernet impl -> Arp.arpv4 impl -> ipv4 impl

val keyed_create_ipv4 :
  ?group:string ->
  ?network:Ipaddr.V4.Prefix.t ->
  ?gateway:Ipaddr.V4.t ->
  no_init:bool runtime_arg ->
  Ethernet.ethernet impl ->
  Arp.arpv4 impl ->
  ipv4 impl

val create_ipv6 :
  ?group:string -> Network.network impl -> Ethernet.ethernet impl -> ipv6 impl

val keyed_create_ipv6 :
  ?group:string ->
  ?network:Ipaddr.V6.Prefix.t ->
  ?gateway:Ipaddr.V6.t ->
  no_init:bool runtime_arg ->
  Network.network impl ->
  Ethernet.ethernet impl ->
  ipv6 impl

val ipv4_of_dhcp :
  Network.network impl -> Ethernet.ethernet impl -> Arp.arpv4 impl -> ipv4 impl

val ipv4_qubes :
  Qubesdb.qubesdb impl -> Ethernet.ethernet impl -> Arp.arpv4 impl -> ipv4 impl

val create_ipv4v6 : ?group:string -> ipv4 impl -> ipv6 impl -> ipv4v6 impl

val keyed_ipv4v6 :
  ipv4_only:bool runtime_arg ->
  ipv6_only:bool runtime_arg ->
  ipv4 impl ->
  ipv6 impl ->
  ipv4v6 impl

val right_tcpip_library : string list -> package
