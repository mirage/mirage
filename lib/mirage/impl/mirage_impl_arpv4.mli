open Functoria

type arpv4

val arpv4 : arpv4 typ

val arp :
  ?time:Mirage_impl_time.time impl ->
  Mirage_impl_ethernet.ethernet impl ->
  arpv4 impl
