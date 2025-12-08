open Functoria.DSL

type v4
type v6
type v4v6
type 'a ip
type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip
type dhcp_ipv4
type lease

val ip : 'a ip typ
val ipv4 : ipv4 typ
val ipv6 : ipv6 typ
val ipv4v6 : ipv4v6 typ
val dhcp_ipv4 : dhcp_ipv4 typ
val lease : lease typ

module Dhcp_requests : sig
  type t

  val add : t -> int -> unit
  val make : unit -> t
end

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

val keyed_ipv4_of_dhcp :
  ?group:string ->
  ?dhcp_requests:Dhcp_requests.t ->
  ?gateway:Ipaddr.V4.t ->
  no_init:bool runtime_arg ->
  Network.network impl ->
  Ethernet.ethernet impl ->
  Arp.arpv4 impl ->
  dhcp_ipv4 impl

val ipv4_of_dhcp :
  ?group:string ->
  ?dhcp_requests:Dhcp_requests.t ->
  ?gateway:Ipaddr.V4.t ->
  Network.network impl ->
  Ethernet.ethernet impl ->
  Arp.arpv4 impl ->
  dhcp_ipv4 impl

val dhcp_proj_net : (dhcp_ipv4 -> Network.network) impl
val dhcp_proj_ipv4 : (dhcp_ipv4 -> ipv4) impl
val dhcp_proj_lease : (dhcp_ipv4 -> lease) impl

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
