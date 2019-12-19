open Functoria.DSL

type ethernet

val ethernet : ethernet typ

val etif : Mirage_impl_network.network impl -> ethernet impl
