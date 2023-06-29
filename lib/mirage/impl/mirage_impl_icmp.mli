open Functoria

type icmpv4

val icmpv4 : icmpv4 typ
val direct_icmpv4 : Mirage_impl_ip.ipv4 impl -> icmpv4 impl
