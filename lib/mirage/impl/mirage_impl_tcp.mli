open Functoria

type 'a tcp

val tcp : 'a tcp typ

type tcpv4v6 = Mirage_impl_ip.v4v6 tcp

val tcpv4v6 : tcpv4v6 typ

val direct_tcp :
  ?mclock:Mirage_impl_mclock.mclock impl ->
  ?time:Mirage_impl_time.time impl ->
  ?random:Mirage_impl_random.random impl ->
  'a Mirage_impl_ip.ip impl ->
  'a tcp impl

val socket_tcpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> tcpv4v6 impl

val tcpv4v6_socket_conf :
  ipv4_only:bool runtime_key ->
  ipv6_only:bool runtime_key ->
  Ipaddr.V4.Prefix.t runtime_key ->
  Ipaddr.V6.Prefix.t option runtime_key ->
  tcpv4v6 impl
