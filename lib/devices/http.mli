open Functoria

type http

val http : http typ
val cohttp_server : Conduit.conduit impl -> http impl
val httpaf_server : Conduit.conduit impl -> http impl

type http_client

val http_client : http_client typ

val cohttp_client :
  ?pclock:Pclock.pclock impl ->
  Resolver.resolver impl ->
  Conduit.conduit impl ->
  http_client impl

type http_server

val http_server : http_server typ
val paf_server : int runtime_arg -> (Tcp.tcpv4v6 -> http_server) impl

type alpn_client

val alpn_client : alpn_client typ

val paf_client :
  (Pclock.pclock -> Tcp.tcpv4v6 -> Mimic.mimic -> alpn_client) impl
