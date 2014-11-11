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

open V2

module type TIME = TIME
  with type 'a io = 'a Lwt.t

module type FLOW = FLOW
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

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

(** IP stack *)
module type IP = IP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

(** IPv4 stack *)
module type IPV4 = IPV4
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type macaddr = Macaddr.t
   and type ipaddr = Ipaddr.V4.t

(** IPv6 stack *)
module type IPV6 = IPV6
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V6.t

(** UDPv4 stack *)
module type UDP = UDP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V4.t

(** TCPv4 stack *)
module type TCP = TCP
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V4.t

(** Buffered TCPv4 channel *)
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

(** Entropy *)
module type ENTROPY = ENTROPY
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t

(** Block devices *)
module type BLOCK = BLOCK
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

(** FS *)
module type FS = FS
  with type 'a io = 'a Lwt.t

type socket_stack_config =
  Ipaddr.V4.t list * Ipaddr.V6.t list

type direct_stack_config = [
    `DHCP
  | `IP of Ipaddr.V4.t * Ipaddr.V4.t * Ipaddr.V4.t list
]

type ('console, 'netif, 'mode) stack_config = {
  name: string;
  console: 'console;
  interface: 'netif;
  mode: 'mode;
}

(** Single network stack *)
module type STACK = STACK
  with type 'a io = 'a Lwt.t
   and type ('a,'b,'c) config = ('a,'b,'c) stack_config
   and type ipv4addr = Ipaddr.V4.t
   and type ipv6addr = Ipaddr.V6.t
   and type buffer = Cstruct.t
