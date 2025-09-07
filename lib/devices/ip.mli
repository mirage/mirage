open Functoria
open Arp
open Ethernet
open Network
open Qubesdb

type v4
type v6
type v4v6
type 'a ip
type ipv4 = v4 ip
type ipv6 = v6 ip
type ipv4v6 = v4v6 ip

val ip : 'a ip typ
val ipv4 : ipv4 typ
val ipv6 : ipv6 typ
val ipv4v6 : ipv4v6 typ
val create_ipv4 : ?group:string -> ethernet impl -> arpv4 impl -> ipv4 impl

val keyed_create_ipv4 :
  ?group:string ->
  no_init:bool runtime_arg ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl

val create_ipv6 : ?group:string -> network impl -> ethernet impl -> ipv6 impl

val keyed_create_ipv6 :
  ?group:string ->
  no_init:bool runtime_arg ->
  network impl ->
  ethernet impl ->
  ipv6 impl

val ipv4_of_dhcp : network impl -> ethernet impl -> arpv4 impl -> ipv4 impl
val ipv4_qubes : qubesdb impl -> ethernet impl -> arpv4 impl -> ipv4 impl
val create_ipv4v6 : ?group:string -> ipv4 impl -> ipv6 impl -> ipv4v6 impl

val keyed_ipv4v6 :
  ipv4_only:bool runtime_arg ->
  ipv6_only:bool runtime_arg ->
  ipv4 impl ->
  ipv6 impl ->
  ipv4v6 impl

val right_tcpip_library :
  ?libs:string list -> sublibs:string list -> string -> package list value
