open Functoria

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
  (Mclock.mclock -> Tcp.tcpv4v6 -> Time.time -> Mimic.mimic -> git_client) impl

val git_http :
  ?group:string ->
  ?authenticator:string ->
  ?headers:(string * string) list ->
  unit ->
  (Pclock.pclock -> Tcp.tcpv4v6 -> Mimic.mimic -> git_client) impl
