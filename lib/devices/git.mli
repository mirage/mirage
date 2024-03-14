open Functoria

type git_client

val git_client : git_client typ
val git_merge_clients : (git_client -> git_client -> git_client) impl
val git_tcp : (Tcp.tcpv4v6 -> Mimic.mimic -> git_client) impl

val git_ssh :
  ?authenticator:string option runtime_arg ->
  string option runtime_arg ->
  string option runtime_arg ->
  (Mclock.mclock -> Tcp.tcpv4v6 -> Time.time -> Mimic.mimic -> git_client) impl

val git_http :
  ?authenticator:string option runtime_arg ->
  (string * string) list runtime_arg option ->
  (Pclock.pclock -> Tcp.tcpv4v6 -> Mimic.mimic -> git_client) impl
