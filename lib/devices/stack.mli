open Functoria.DSL

type stackv4v6

val stackv4v6 : stackv4v6 typ

val direct_stackv4v6 :
  ?group:string ->
  ?tcp:Tcp.tcpv4v6 impl ->
  Network.network impl ->
  Ethernet.ethernet impl ->
  Arp.arpv4 impl ->
  Ip.ipv4 impl ->
  Ip.ipv6 impl ->
  stackv4v6 impl

val generic_stackv4v6 :
  ?group:string ->
  ?dhcp_key:bool value ->
  ?net_key:[ `OCaml | `Host ] option value ->
  ?ipv4_network:Ipaddr.V4.Prefix.t ->
  ?ipv4_gateway:Ipaddr.V4.t ->
  ?ipv6_network:Ipaddr.V6.Prefix.t ->
  ?ipv6_gateway:Ipaddr.V6.t ->
  ?tcp:Tcp.tcpv4v6 impl ->
  Network.network impl ->
  stackv4v6 impl
