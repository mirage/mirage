open Functoria

type conduit

val pkg : package
val conduit : conduit typ

val conduit_direct :
  ?tls:bool ->
  ?random:Random.random impl ->
  Stack.stackv4v6 impl ->
  conduit impl
