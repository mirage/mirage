type arpv4

val arpv4 : arpv4 Functoria.typ

val arp :
  ?time:Mirage_impl_time.time Functoria.impl ->
  Mirage_impl_ethernet.ethernet Functoria.impl ->
  arpv4 Functoria.impl
