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
   and type ipv4addr = Ipaddr.V4.t

(** IPv4 stack *)
module type IPV4 = IPV4
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipaddr = Ipaddr.V4.t

(** UDPv4 stack *)
module type UDPV4 = UDPV4
  with type 'a io = 'a Lwt.t
   and type buffer = Cstruct.t
   and type ipv4addr = Ipaddr.V4.t

(** KV RO *)
module type KV_RO = KV_RO
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

(** Consoles *)
module type CONSOLE = CONSOLE
  with type 'a io = 'a Lwt.t

(** Block devices *)
module type BLOCK = BLOCK
  with type 'a io = 'a Lwt.t
   and type page_aligned_buffer = Cstruct.t

(** FS *)
module type FS = FS
  with type 'a io = 'a Lwt.t
