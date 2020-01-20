type http

val http : http Functoria.typ

val cohttp_server :
  Mirage_impl_conduit.conduit Functoria.impl -> http Functoria.impl

val httpaf_server :
  Mirage_impl_conduit.conduit Functoria.impl -> http Functoria.impl
