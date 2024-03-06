open Functoria

type git_client

val git_client : git_client typ
val git_merge_clients : (git_client -> git_client -> git_client) impl

val git_tcp :
  (Mirage_impl_tcp.tcpv4v6 -> Mirage_impl_mimic.mimic -> git_client) impl

val git_ssh :
  ?authenticator:string option runtime_arg ->
  string option runtime_arg ->
  string option runtime_arg ->
  (Mirage_impl_mclock.mclock ->
  Mirage_impl_tcp.tcpv4v6 ->
  Mirage_impl_time.time ->
  Mirage_impl_mimic.mimic ->
  git_client)
  impl

val git_http :
  ?authenticator:string option runtime_arg ->
  (string * string) list runtime_arg option ->
  (Mirage_impl_pclock.pclock ->
  Mirage_impl_tcp.tcpv4v6 ->
  Mirage_impl_mimic.mimic ->
  git_client)
  impl
