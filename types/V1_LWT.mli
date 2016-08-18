(*
 * Copyright (c) 2011-2014 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013-2014 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2014 Citrix Systems Inc
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open V1

module type TIME = TIME
  with type 'a io = 'a Lwt.t

module type FLOW = FLOW
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

module type PCLOCK = PCLOCK
  with type 'a io = 'a Lwt.t

module type MCLOCK = MCLOCK
  with type 'a io = 'a Lwt.t

(** Network *)
module type NETWORK = NETWORK
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Io_page.t
   and type buffer = Cstruct.t
   and type macaddr = Macaddr.t

(** Ethernet interface *)
module type ETHIF = ETHIF
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type macaddr = Macaddr.t

(** ARP interface *)
module type ARP = ARP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V4.t
   and type macaddr = Macaddr.t

(** IP stack *)
module type IP = IP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type uipaddr = Ipaddr.t

(** IPv4 stack *)
module type IPV4 = IPV4
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V4.t
   and type prefix = Ipaddr.V4.t (* FIXME: Use Ipaddr.V4.Prefix.t *)
   and type uipaddr = Ipaddr.t

(** IPv6 stack *)
module type IPV6 = IPV6
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V6.t
   and type prefix = Ipaddr.V6.Prefix.t
   and type uipaddr = Ipaddr.t

(** ICMP module *)
module type ICMP = ICMP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

(** ICMPV4 module *)
module type ICMPV4 = ICMPV4
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V4.t

(** UDP stack *)
module type UDP = UDP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

(** UDP stack over IPv4 *)
module type UDPV4 = UDP
  with type ipaddr = Ipaddr.V4.t

(** UDP stack over IPv6 *)
module type UDPV6 = UDP
  with type ipaddr = Ipaddr.V6.t

(** TCP stack *)
module type TCP = TCP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

(** TCP stack over IPv4 *)
module type TCPV4 = TCP
  with type ipaddr = Ipaddr.V4.t

(** TCP stack over IPv6 *)
module type TCPV6 = TCP
  with type ipaddr = Ipaddr.V6.t

(** Buffered TCP channel *)
module type CHANNEL = CHANNEL
  with type 'a io = 'a Lwt.t
   and type 'a io_stream = 'a Lwt_stream.t
   and type buffer = Cstruct.t

(** KV RO *)
module type KV_RO = KV_RO
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

(** Consoles *)
module type CONSOLE = CONSOLE
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

(** Block devices *)
module type BLOCK = BLOCK
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

(** FS *)
module type FS = FS
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

type socket_stack_config =
  Ipaddr.V4.t list

type direct_stack_config = [
    `DHCP
  | `IPv4 of Ipaddr.V4.t * Ipaddr.V4.t * Ipaddr.V4.t list
]

type ('netif, 'mode) stackv4_config = {
  name: string;
  interface: 'netif;
  mode: 'mode;
}

(** Single network stack *)
module type STACKV4 = STACKV4
  with type 'a io = 'a Lwt.t
   and type ('a,'b) config = ('a,'b) stackv4_config
   and type ipv4addr = Ipaddr.V4.t
   and type buffer = Cstruct.t
