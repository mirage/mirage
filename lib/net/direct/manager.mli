(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

(* The manager process binds application ports to interfaces, and
   will eventually deal with load balancing and route determination
   (e.g. if a remote target is on the same host, swap to shared memory *)

open Nettypes
exception Error of string

type config = [ `DHCP | `IPv4 of ipv4_addr * ipv4_addr * ipv4_addr list ]

type id = OS.Netif.id
type interface
type t

val plug: t -> id -> OS.Netif.t -> unit Lwt.t
val unplug: t -> id -> unit

val configure: interface -> config -> unit Lwt.t
 
val create : (t -> interface -> id -> unit Lwt.t) -> unit Lwt.t

val tcpv4_of_addr : t -> ipv4_addr option -> Tcp.Pcb.t list
val udpv4_of_addr : t -> ipv4_addr option -> Udp.t list
