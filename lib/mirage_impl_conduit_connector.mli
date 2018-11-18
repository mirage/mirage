type conduit_connector

val tcp_conduit_connector :
  (Mirage_impl_stackv4.stackv4 -> conduit_connector) Functoria.impl

val tls_conduit_connector : conduit_connector Functoria.impl

val pkg : Functoria.package
