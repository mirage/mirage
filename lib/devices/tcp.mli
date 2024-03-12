open Functoria

type 'a tcp

val tcp : 'a tcp typ

type tcpv4v6 = Ip.v4v6 tcp

val tcpv4v6 : tcpv4v6 typ

val direct_tcp :
  ?mclock:Mclock.mclock impl ->
  ?time:Time.time impl ->
  ?random:Random.random impl ->
  'a Ip.ip impl ->
  'a tcp impl

val socket_tcpv4v6 :
  ?group:string -> Ipaddr.V4.t option -> Ipaddr.V6.t option -> tcpv4v6 impl

val tcpv4v6_socket_conf :
  ipv4_only:bool runtime_arg ->
  ipv6_only:bool runtime_arg ->
  Ipaddr.V4.Prefix.t runtime_arg ->
  Ipaddr.V6.Prefix.t option runtime_arg ->
  tcpv4v6 impl
