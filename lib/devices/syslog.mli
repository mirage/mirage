open Functoria

type syslog

val syslog : syslog typ

val syslog_udp :
  ?group:string ->
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  syslog impl

val syslog_tcp :
  ?group:string ->
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  syslog impl

val syslog_tls :
  ?group:string ->
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  Kv.ro impl ->
  syslog impl

val monitoring :
  ?group:string ->
  ?time:Time.time impl ->
  ?clock:Pclock.pclock impl ->
  Stack.stackv4v6 impl ->
  Functoria.job impl
