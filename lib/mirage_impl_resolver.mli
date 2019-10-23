type resolver

val resolver : resolver Functoria.typ

val resolver_dns :
     ?ns:Ipaddr.V4.t
  -> ?ns_port:int
  -> ?entry_points:Mirage_impl_entry_points.entry_points Functoria.impl
  -> ?random:Mirage_impl_random.random Functoria.impl
  -> ?time:Mirage_impl_time.time Functoria.impl
  -> Mirage_impl_stackv4.stackv4 Functoria.impl
  -> resolver Functoria.impl

val resolver_unix_system : resolver Functoria.impl
