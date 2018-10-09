type arpv4

val arpv4 : arpv4 Functoria.typ

val arp :
     ?clock:Mirage_impl_mclock.mclock Functoria.impl
  -> ?time:Mirage_impl_time.time Functoria.impl
  -> Mirage_impl_ethernet.ethernet Functoria.impl
  -> arpv4 Functoria.impl

val farp :
     ?clock:Mirage_impl_mclock.mclock Functoria.impl
  -> ?time:Mirage_impl_time.time Functoria.impl
  -> Mirage_impl_ethernet.ethernet Functoria.impl
  -> arpv4 Functoria.impl
