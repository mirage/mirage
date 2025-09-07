open Functoria

type stackv4v6

val stackv4v6 : stackv4v6 typ

val direct_stackv4v6 :
  ?group:string ->
  ?tcp:Tcp.tcpv4v6 impl ->
  Network.network impl ->
  Ethernet.ethernet impl ->
  Arp.arpv4 impl ->
  Ip.ipv4 impl ->
  Ip.ipv6 impl ->
  stackv4v6 impl

val generic_stackv4v6 :
  ?group:string ->
  ?ipv6_config:Ip.ipv6_config ->
  ?ipv4_config:Ip.ipv4_config ->
  ?dhcp_key:bool value ->
  ?net_key:[ `OCaml | `Host ] option value ->
  ?tcp:Tcp.tcpv4v6 impl ->
  Network.network impl ->
  stackv4v6 impl
