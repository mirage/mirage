open Functoria

type arpv4

val arpv4 : arpv4 typ
val arp : ?time:Time.time impl -> Ethernet.ethernet impl -> arpv4 impl
