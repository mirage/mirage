type 'a udp

val udp : 'a udp Functoria.typ

type udpv4 = Mirage_impl_ip.v4 udp
type udpv6 = Mirage_impl_ip.v6 udp
type udpv4v6 = Mirage_impl_ip.v4v6 udp

val udpv4 : udpv4 Functoria.typ
val udpv6 : udpv6 Functoria.typ
val udpv4v6 : udpv4v6 Functoria.typ

val direct_udp :
?random:Mirage_impl_random.random Functoria.impl -> 'a Mirage_impl_ip.ip
Functoria.impl -> 'a udp Functoria.impl

val socket_udpv4:
?group:string -> Ipaddr.V4.t option -> udpv4 Functoria.impl

val keyed_socket_udpv4 : Ipaddr.V4.Prefix.t Mirage_key.key -> udpv4 Functoria.impl

val socket_udpv6:
?group:string -> Ipaddr.V6.t option -> udpv6 Functoria.impl

val keyed_socket_udpv6 : Ipaddr.V6.Prefix.t option Mirage_key.key -> udpv6 Functoria.impl

val socket_udpv4v6:
?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> udpv4v6 Functoria.impl

val keyed_socket_udpv4v6 : Ipaddr.V4.Prefix.t Mirage_key.key -> Ipaddr.V6.Prefix.t option Mirage_key.key -> udpv4v6 Functoria.impl
