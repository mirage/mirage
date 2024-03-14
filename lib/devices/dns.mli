open Functoria

type dns_client

val dns_client : dns_client typ

val generic_dns_client :
  int64 option runtime_arg option ->
  string list runtime_arg option ->
  (Random.random ->
  Time.time ->
  Mclock.mclock ->
  Pclock.pclock ->
  Stack.stackv4v6 ->
  dns_client)
  impl
