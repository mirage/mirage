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
