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

open Nettypes

type t
type interface
type id
val create : (t -> interface -> id -> unit Lwt.t) -> unit Lwt.t

type config = [ `DHCP | `IPv4 of ipv4_addr * ipv4_addr * ipv4_addr list ]
val configure: interface -> config -> unit Lwt.t

val local_peers : 'a -> OS.Socket.uid list
val local_uid : 'a -> OS.Socket.uid
val connect_to_peer : t -> peer_uid -> [ `domain ] OS.Socket.fd option Lwt.t
val listen_to_peers : t -> (int -> [< `rd_pipe | `wr_pipe ] OS.Socket.fd * [< `rd_pipe | `wr_pipe ] OS.Socket.fd -> unit Lwt.t) -> unit Lwt.t
val connect : t -> peer_uid -> ([ `rd_pipe ] OS.Socket.fd * [ `wr_pipe ] OS.Socket.fd -> 'a Lwt.t) -> 'a Lwt.t
val get_udpv4 : t -> [ `udpv4 ] OS.Socket.fd
val register_udpv4_listener : t -> ipv4_addr option * int -> [ `udpv4 ] OS.Socket.fd -> unit
val get_udpv4_listener : t -> ipv4_addr option * OS.Socket.port -> [ `udpv4 ] OS.Socket.fd Lwt.t

