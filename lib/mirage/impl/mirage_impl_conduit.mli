open Functoria

type conduit

val pkg : package
val conduit : conduit typ

val conduit_direct :
  ?tls:bool ->
  ?random:Mirage_impl_random.random impl ->
  Mirage_impl_stack.stackv4v6 impl ->
  conduit impl
