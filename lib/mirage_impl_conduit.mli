open Functoria.DSL

type conduit

val conduit : conduit typ

val conduit_direct :
     ?tls:bool
  -> Mirage_impl_stackv4.stackv4 impl
  -> conduit impl
