open Functoria.DSL

type http

val http : http typ

val cohttp_server :
  Mirage_impl_conduit.conduit impl -> http impl

val httpaf_server :
  Mirage_impl_conduit.conduit impl -> http impl
