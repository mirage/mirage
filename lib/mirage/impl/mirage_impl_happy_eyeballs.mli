open Functoria

type happy_eyeballs

val happy_eyeballs : happy_eyeballs typ

val generic_happy_eyeballs :
  int64 option runtime_arg option ->
  int64 option runtime_arg option ->
  int64 option runtime_arg option ->
  int64 option runtime_arg option ->
  int64 option runtime_arg option ->
  int64 option runtime_arg option ->
  (Mirage_impl_time.time ->
  Mirage_impl_mclock.mclock ->
  Mirage_impl_stack.stackv4v6 ->
  Mirage_impl_dns.dns_client ->
  happy_eyeballs)
  impl
