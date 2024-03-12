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
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  syslog impl

val syslog_tcp :
  ?config:syslog_config ->
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  syslog impl

val syslog_tls :
  ?config:syslog_config ->
  ?keyname:string ->
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  Kv.ro impl ->
  syslog impl
