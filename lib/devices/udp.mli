open Functoria.DSL

type 'a udp

val udp : 'a udp typ

type udpv4v6 = Ip.v4v6 udp

val udpv4v6 : udpv4v6 typ
val direct_udp : 'a Ip.ip impl -> 'a udp impl

val socket_udpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> udpv4v6 impl

val udpv4v6_socket_conf :
  ipv4_only:bool runtime_arg ->
  ipv6_only:bool runtime_arg ->
  Ipaddr.V4.Prefix.t runtime_arg ->
  Ipaddr.V6.Prefix.t option runtime_arg ->
  udpv4v6 impl
