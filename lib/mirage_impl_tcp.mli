open Functoria.DSL

type 'a tcp

val tcp : 'a tcp typ

type tcpv4 = Mirage_impl_ip.v4 tcp

type tcpv6 = Mirage_impl_ip.v6 tcp

val tcpv4 : tcpv4 typ

val tcpv6 : tcpv6 typ

val direct_tcp :
     ?clock:Mirage_impl_mclock.mclock impl
  -> ?random:Mirage_impl_random.random impl
  -> ?time:Mirage_impl_time.time impl
  -> 'a Mirage_impl_ip.ip impl
  -> 'a tcp impl

val socket_tcpv4 : ?group:string -> Ipaddr.V4.t option -> tcpv4 impl
