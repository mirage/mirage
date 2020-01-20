type conduit

val conduit : conduit Functoria.typ

val conduit_direct :
  ?tls:bool ->
  Mirage_impl_stackv4.stackv4 Functoria.impl ->
  conduit Functoria.impl
