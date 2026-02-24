open Functoria.DSL

type resolver

val resolver : resolver typ

val resolver_dns :
  ?dhcp:Ip.Dhcp_requests.t * Ip.lease impl ->
  ?ns:string list ->
  Stack.stackv4v6 impl ->
  resolver impl

val resolver_unix_system : resolver impl
