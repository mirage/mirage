type 'a tcp

val tcp : 'a tcp Functoria.typ

type tcpv4v6 = Mirage_impl_ip.v4v6 tcp

val tcpv4v6 : tcpv4v6 Functoria.typ

val direct_tcp :
  ?mclock:Mirage_impl_mclock.mclock Functoria.impl ->
  ?time:Mirage_impl_time.time Functoria.impl ->
  ?random:Mirage_impl_random.random Functoria.impl ->
  'a Mirage_impl_ip.ip Functoria.impl ->
  'a tcp Functoria.impl

val socket_tcpv4v6 :
  ?group:string ->
  Ipaddr.V4.t option ->
  Ipaddr.V6.t option ->
  tcpv4v6 Functoria.impl

val tcpv4v6_socket_conf :
  ipv4_only:bool Mirage_key.key ->
  ipv6_only:bool Mirage_key.key ->
  Ipaddr.V4.Prefix.t Mirage_key.key ->
  Ipaddr.V6.Prefix.t option Mirage_key.key ->
  tcpv4v6 Functoria.impl
