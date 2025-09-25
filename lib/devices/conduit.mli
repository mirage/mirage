open Functoria.DSL

type conduit

val pkg : package
val conduit : conduit typ
val conduit_direct : ?tls:bool -> Stack.stackv4v6 impl -> conduit impl
