type resolver

val resolver : resolver Functoria.typ

val resolver_dns :
     ?ns:Ipaddr.t
  -> ?ns_port:int
  -> ?random:Mirage_impl_random.random Functoria.impl
  -> ?time:Mirage_impl_time.time Functoria.impl
  -> ?mclock:Mirage_impl_mclock.mclock Functoria.impl
  -> ?pclock:Mirage_impl_pclock.pclock Functoria.impl
  -> Mirage_impl_stack.stackv4v6 Functoria.impl
  -> resolver Functoria.impl

val resolver_unix_system : resolver Functoria.impl
