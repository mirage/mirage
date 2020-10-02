type c_tcp
type c_tls
type 'a conduit
type tcp_conduit = c_tcp conduit
type tls_conduit = c_tls conduit

val conduit : 'a conduit Functoria.typ
val tcp_conduit : tcp_conduit Functoria.typ
val tls_conduit : tls_conduit Functoria.typ

val create_tcp_conduit :
  Mirage_impl_stackv4.stackv4 Functoria.impl -> tcp_conduit Functoria.impl

val create_tls_conduit : 'a conduit Functoria.impl -> tls_conduit Functoria.impl

val pkg : string list -> Functoria.package
