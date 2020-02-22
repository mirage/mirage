open Functoria
open Mirage_impl_arpv4
open Mirage_impl_ethernet
open Mirage_impl_mclock
open Mirage_impl_network
open Mirage_impl_qubesdb
open Mirage_impl_random

type v4

type v6

type 'a ip

type ipv4 = v4 ip

type ipv6 = v6 ip

val ip : 'a ip Functoria.typ

val ipv4 : ipv4 Functoria.typ

val ipv6 : ipv6 Functoria.typ

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t * Ipaddr.V4.t;
  gateway : Ipaddr.V4.t option;
}

type ipv6_config = {
  addresses : Ipaddr.V6.t list;
  netmasks : Ipaddr.V6.Prefix.t list;
  gateways : Ipaddr.V6.t list;
}

val create_ipv4 :
  ?group:string ->
  ?config:ipv4_config ->
  ?random:random impl ->
  ?clock:mclock impl ->
  ethernet impl ->
  arpv4 impl ->
  ipv4 impl

val create_ipv6 :
  ?random:random impl ->
  ?time:Mirage_impl_time.time impl ->
  ?clock:mclock impl ->
  ?group:string ->
  ethernet impl ->
  ipv6_config ->
  ipv6 impl

val dhcp :
  random impl ->
  Mirage_impl_time.time impl ->
  network impl ->
  Mirage_impl_dhcp.dhcp impl

val ipv4_of_dhcp :
  ?random:random impl ->
  ?clock:mclock impl ->
  Mirage_impl_dhcp.dhcp impl ->
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

val right_tcpip_library :
  ?libs:string list -> sublibs:string list -> string -> package list value
