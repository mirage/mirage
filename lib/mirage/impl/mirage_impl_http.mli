open Functoria

type http

val http : http typ
val cohttp_server : Mirage_impl_conduit.conduit impl -> http impl
val httpaf_server : Mirage_impl_conduit.conduit impl -> http impl

type http_client

val http_client : http_client typ

val cohttp_client :
  ?pclock:Mirage_impl_pclock.pclock impl ->
  Mirage_impl_resolver.resolver impl ->
  Mirage_impl_conduit.conduit impl ->
  http_client impl

type http_server

val http_server : http_server typ

val paf_server :
  int Mirage_key.key -> (Mirage_impl_tcp.tcpv4v6 -> http_server) impl

type alpn_client

val alpn_client : alpn_client typ

val paf_client :
  (Mirage_impl_pclock.pclock ->
  Mirage_impl_tcp.tcpv4v6 ->
  Mirage_impl_mimic.mimic ->
  alpn_client)
  impl
