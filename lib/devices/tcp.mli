open Functoria

type 'a tcp

val tcp : 'a tcp typ

type tcpv4v6 = Ip.v4v6 tcp

val tcpv4v6 : tcpv4v6 typ

val tcp_impl :
  ?mclock:Mclock.mclock impl ->
  ?time:Time.time impl ->
  ?random:Random.random impl ->
  'a Ip.ip impl ->
  'a tcp impl
