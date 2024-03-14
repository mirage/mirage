open Functoria
open Arp
open Ethernet
open Mclock
open Network
open Qubesdb
open Random

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

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}

type ipv6_config = {
  network : Ipaddr.V6.Prefix.t;
  gateway : Ipaddr.V6.t option;
}

val create_ipv4 :
  ?group:string ->
  ?config:ipv4_config ->
  ?no_init:bool runtime_arg ->
  ?random:random impl ->
  ?clock:mclock impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl

val create_ipv6 :
  ?random:random impl ->
  ?time:Time.time impl ->
  ?clock:mclock impl ->
  ?group:string ->
  ?config:ipv6_config ->
  ?no_init:bool runtime_arg ->
  network impl ->
  ethernet impl ->
  ipv6 impl

val ipv4_of_dhcp :
  ?random:random impl ->
  ?clock:mclock impl ->
  ?time:Time.time impl ->
  network impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl

val ipv4_qubes :
  ?random:random impl ->
  ?clock:mclock impl ->
  qubesdb impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl

val create_ipv4v6 : ?group:string -> ipv4 impl -> ipv6 impl -> ipv4v6 impl

val keyed_ipv4v6 :
  ipv4_only:bool runtime_arg ->
  ipv6_only:bool runtime_arg ->
  ipv4 impl ->
  ipv6 impl ->
  ipv4v6 impl

val right_tcpip_library :
  ?libs:string list -> sublibs:string list -> string -> package list value
