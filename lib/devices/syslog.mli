open Functoria.DSL

type syslog

val syslog : syslog typ
val syslog_udp : ?group:string -> Stack.stackv4v6 impl -> syslog impl
val syslog_tcp : ?group:string -> Stack.stackv4v6 impl -> syslog impl

val syslog_tls :
  ?group:string -> Stack.stackv4v6 impl -> Kv.ro impl -> syslog impl

val monitoring : ?group:string -> Stack.stackv4v6 impl -> Functoria.job impl
