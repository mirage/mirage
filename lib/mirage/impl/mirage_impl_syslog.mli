type syslog

val syslog : syslog Functoria.typ

type syslog_config = {
  hostname : string;
  server : Ipaddr.t option;
  port : int option;
  truncate : int option;
}

val syslog_config :
  ?port:int -> ?truncate:int -> ?server:Ipaddr.t -> string -> syslog_config

val syslog_udp :
  ?config:syslog_config ->
  ?clock:Mirage_impl_pclock.pclock Functoria.impl ->
  Mirage_impl_stack.stackv4v6 Functoria.impl ->
  syslog Functoria.impl

val syslog_tcp :
  ?config:syslog_config ->
  ?clock:Mirage_impl_pclock.pclock Functoria.impl ->
  Mirage_impl_stack.stackv4v6 Functoria.impl ->
  syslog Functoria.impl

val syslog_tls :
  ?config:syslog_config ->
  ?keyname:string ->
  ?clock:Mirage_impl_pclock.pclock Functoria.impl ->
  Mirage_impl_stack.stackv4v6 Functoria.impl ->
  Mirage_impl_kv.ro Functoria.impl ->
  syslog Functoria.impl
