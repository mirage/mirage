type 'a udp

val udp : 'a udp Functoria.typ

type udpv4v6 = Mirage_impl_ip.v4v6 udp

val udpv4v6 : udpv4v6 Functoria.typ

val direct_udp :
  ?random:Mirage_impl_random.random Functoria.impl ->
  'a Mirage_impl_ip.ip Functoria.impl ->
  'a udp Functoria.impl

val socket_udpv4v6 :
  ?group:string ->
  Ipaddr.V4.t option ->
  Ipaddr.V6.t option ->
  udpv4v6 Functoria.impl

val udpv4v6_socket_conf :
  ipv4_only:bool Mirage_key.key ->
  ipv6_only:bool Mirage_key.key ->
  Ipaddr.V4.Prefix.t Mirage_key.key ->
  Ipaddr.V6.Prefix.t option Mirage_key.key ->
  udpv4v6 Functoria.impl
