open Functoria

type syslog

val syslog : syslog typ

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
  ?clock:Mirage_impl_pclock.pclock impl ->
  Mirage_impl_stack.stackv4v6 impl ->
  syslog impl

val syslog_tcp :
  ?config:syslog_config ->
  ?clock:Mirage_impl_pclock.pclock impl ->
  Mirage_impl_stack.stackv4v6 impl ->
  syslog impl

val syslog_tls :
  ?config:syslog_config ->
  ?keyname:string ->
  ?clock:Mirage_impl_pclock.pclock impl ->
  Mirage_impl_stack.stackv4v6 impl ->
  Mirage_impl_kv.ro impl ->
  syslog impl
