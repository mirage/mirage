(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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
 *
 *)

open Nettypes

type t

val input : t -> OS.Io_page.t -> unit Lwt.t
val listen : t -> unit Lwt.t
val output : t -> OS.Io_page.t -> unit Lwt.t
val create : OS.Netif.t -> t * unit Lwt.t

val add_ip : t -> Nettypes.ipv4_addr -> unit Lwt.t
val remove_ip : t -> Nettypes.ipv4_addr -> unit Lwt.t
val query_arp : t -> Nettypes.ipv4_addr -> Nettypes.ethernet_mac Lwt.t

val get_etherbuf : t -> OS.Io_page.t Lwt.t

val attach : t -> [< `IPv4 of OS.Io_page.t -> unit Lwt.t ] -> unit
val detach : t -> [< `IPv4 ] -> unit
val mac : t -> Nettypes.ethernet_mac
val get_ethif : t -> OS.Netif.t

val sizeof_ethernet : int
val set_ethernet_dst : string -> int -> OS.Io_page.t -> unit
val set_ethernet_src : string -> int -> OS.Io_page.t -> unit
val set_ethernet_ethertype : OS.Io_page.t -> int -> unit
