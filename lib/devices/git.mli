open Functoria.DSL

type git_client

val git_client : git_client typ
val git_merge_clients : (git_client -> git_client -> git_client) impl
val git_tcp : (Tcp.tcpv4v6 -> Mimic.mimic -> git_client) impl

val git_ssh :
  ?group:string ->
  ?authenticator:string ->
  ?key:string ->
  ?password:string ->
  unit ->
  (Tcp.tcpv4v6 -> Mimic.mimic -> git_client) impl

val git_http :
  ?group:string ->
  ?authenticator:string ->
  ?headers:(string * string) list ->
  unit ->
  (Tcp.tcpv4v6 -> Mimic.mimic -> git_client) impl
