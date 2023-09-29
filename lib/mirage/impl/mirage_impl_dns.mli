open Functoria

type dns_client

val dns_client : dns_client typ

val generic_dns_client :
  int64 option runtime_key option ->
  string list runtime_key option ->
  (Mirage_impl_random.random ->
  Mirage_impl_time.time ->
  Mirage_impl_mclock.mclock ->
  Mirage_impl_pclock.pclock ->
  Mirage_impl_stack.stackv4v6 ->
  dns_client)
  impl
