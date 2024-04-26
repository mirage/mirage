open Functoria.DSL

type 'a udp

val udp : 'a udp typ

type udpv4v6 = Ip.v4v6 udp

val udpv4v6 : udpv4v6 typ

val udp_impl : ?random:Random.random impl -> 'a Ip.ip impl -> 'a udp impl
