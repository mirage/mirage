open Functoria.DSL

type resolver

val resolver : resolver typ
val resolver_dns : ?ns:string list -> Stack.stackv4v6 impl -> resolver impl
val resolver_unix_system : resolver impl
