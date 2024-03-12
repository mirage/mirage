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
  (Time.time ->
  Mclock.mclock ->
  Stack.stackv4v6 ->
  Dns.dns_client ->
  happy_eyeballs)
  impl
