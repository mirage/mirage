open Functoria.DSL

type resolver

val resolver : resolver typ

val resolver_dns :
     ?ns:Ipaddr.V4.t
  -> ?ns_port:int
  -> ?random:Mirage_impl_random.random impl
  -> ?mclock:Mirage_impl_mclock.mclock impl
  -> Mirage_impl_stackv4.stackv4 impl
  -> resolver impl

val resolver_unix_system : resolver impl
