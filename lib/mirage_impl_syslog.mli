open Functoria.DSL

type syslog

val syslog : syslog typ

type syslog_config =
  { hostname: string
  ; server: Ipaddr.V4.t option
  ; port: int option
  ; truncate: int option }

val syslog_config :
  ?port:int -> ?truncate:int -> ?server:Ipaddr.V4.t -> string -> syslog_config

val syslog_udp :
     ?config:syslog_config
  -> ?console:Mirage_impl_console.console impl
  -> ?clock:Mirage_impl_pclock.pclock impl
  -> Mirage_impl_stackv4.stackv4 impl
  -> syslog impl

val syslog_tcp :
     ?config:syslog_config
  -> ?console:Mirage_impl_console.console impl
  -> ?clock:Mirage_impl_pclock.pclock impl
  -> Mirage_impl_stackv4.stackv4 impl
  -> syslog impl

val syslog_tls :
     ?config:syslog_config
  -> ?keyname:string
  -> ?console:Mirage_impl_console.console impl
  -> ?clock:Mirage_impl_pclock.pclock impl
  -> Mirage_impl_stackv4.stackv4 impl
  -> Mirage_impl_kv.ro impl
  -> syslog impl
