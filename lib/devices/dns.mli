open Functoria.DSL

type dns_client

val dns_client : dns_client typ

val generic_dns_client :
  ?group:string ->
  ?timeout:int64 ->
  ?nameservers:string list ->
  ?cache_size:int ->
  unit ->
  (Stack.stackv4v6 -> Happy_eyeballs.happy_eyeballs -> dns_client) impl
