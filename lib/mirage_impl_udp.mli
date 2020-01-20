type 'a udp

val udp : 'a udp Functoria.typ

type udpv4 = Mirage_impl_ip.v4 udp

type udpv6 = Mirage_impl_ip.v6 udp

val udpv4 : udpv4 Functoria.typ

val udpv6 : udpv6 Functoria.typ

val direct_udp :
  ?random:Mirage_impl_random.random Functoria.impl ->
  'a Mirage_impl_ip.ip Functoria.impl ->
  'a udp Functoria.impl

val socket_udpv4 : ?group:string -> Ipaddr.V4.t option -> udpv4 Functoria.impl
