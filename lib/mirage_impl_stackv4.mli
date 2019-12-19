open Functoria.DSL

type stackv4

val stackv4 : stackv4 typ

val direct_stackv4 :
     ?clock:Mirage_impl_mclock.mclock impl
  -> ?random:Mirage_impl_random.random impl
  -> ?time:Mirage_impl_time.time impl
  -> ?group:string
  -> Mirage_impl_network.network impl
  -> Mirage_impl_ethernet.ethernet impl
  -> Mirage_impl_arpv4.arpv4 impl
  -> Mirage_impl_ip.ipv4 impl
  -> stackv4 impl

val socket_stackv4 :
  ?group:string -> Ipaddr.V4.t list -> stackv4 impl

val qubes_ipv4_stack :
     ?group:string
  -> ?qubesdb:Mirage_impl_qubesdb.qubesdb impl
  -> ?arp:(   Mirage_impl_ethernet.ethernet impl
           -> Mirage_impl_arpv4.arpv4 impl)
  -> Mirage_impl_network.network impl
  -> stackv4 impl

val dhcp_ipv4_stack :
     ?group:string
  -> ?random:Mirage_impl_random.random impl
  -> ?time:Mirage_impl_time.time impl
  -> ?arp:(   Mirage_impl_ethernet.ethernet impl
           -> Mirage_impl_arpv4.arpv4 impl)
  -> Mirage_impl_network.network impl
  -> stackv4 impl

val static_ipv4_stack :
     ?group:string
  -> ?config:Mirage_impl_ip.ipv4_config
  -> ?arp:(   Mirage_impl_ethernet.ethernet impl
           -> Mirage_impl_arpv4.arpv4 impl)
  -> Mirage_impl_network.network impl
  -> stackv4 impl

val generic_stackv4 :
     ?group:string
  -> ?config:Mirage_impl_ip.ipv4_config
  -> ?dhcp_key:bool value
  -> ?net_key:[`Direct | `Socket] option value
  -> Mirage_impl_network.network impl
  -> stackv4 impl
