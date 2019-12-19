open Functoria.DSL

type 'a udp

val udp : 'a udp typ

type udpv4 = Mirage_impl_ip.v4 udp
type udpv6 = Mirage_impl_ip.v6 udp

val udpv4 : udpv4 typ
val udpv6 : udpv6 typ

val direct_udp :
?random:Mirage_impl_random.random impl -> 'a Mirage_impl_ip.ip
impl -> 'a udp impl

val socket_udpv4:
?group:string -> Ipaddr.V4.t option -> udpv4 impl
