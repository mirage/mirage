type 'a tcp

val tcp : 'a tcp Functoria.typ

type tcpv4 = Mirage_impl_ip.v4 tcp

type tcpv6 = Mirage_impl_ip.v6 tcp

val tcpv4 : tcpv4 Functoria.typ

val tcpv6 : tcpv6 Functoria.typ

val direct_tcp :
  ?clock:Mirage_impl_mclock.mclock Functoria.impl ->
  ?random:Mirage_impl_random.random Functoria.impl ->
  ?time:Mirage_impl_time.time Functoria.impl ->
  'a Mirage_impl_ip.ip Functoria.impl ->
  'a tcp Functoria.impl

val socket_tcpv4 : ?group:string -> Ipaddr.V4.t option -> tcpv4 Functoria.impl
