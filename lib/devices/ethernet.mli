open Functoria.DSL

type ethernet

val ethernet : ethernet typ
val ethif : Network.network impl -> ethernet impl
