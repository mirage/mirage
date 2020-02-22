type resolver

val resolver : resolver Functoria.typ

val resolver_dns :
  ?ns:Ipaddr.V4.t ->
  ?ns_port:int ->
  ?random:Mirage_impl_random.random Functoria.impl ->
  ?mclock:Mirage_impl_mclock.mclock Functoria.impl ->
  Mirage_impl_stackv4.stackv4 Functoria.impl ->
  resolver Functoria.impl

val resolver_unix_system : resolver Functoria.impl
