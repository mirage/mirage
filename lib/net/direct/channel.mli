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

module TCPv4 : CHANNEL with
      type src = Flow.TCPv4.src
  and type dst = Flow.TCPv4.dst
  and type mgr = Flow.TCPv4.mgr

module Shmem : CHANNEL with
      type src = Flow.Shmem.src
  and type dst = Flow.Shmem.dst
  and type mgr = Flow.Shmem.mgr

type t

val read_char: t -> char option Lwt.t
val read_until: t -> char -> (bool * OS.Istring.t option) option Lwt.t
val read_view: ?len:int -> t -> OS.Istring.t option Lwt.t

val read_crlf: t -> OS.Istring.t Lwt_stream.t

val write_char : t -> char -> unit Lwt.t
val write_string : t -> string -> unit Lwt.t
val write_line : t -> string -> unit Lwt.t

val flush : t -> unit Lwt.t
val close : t -> unit Lwt.t

val connect :
  Manager.t -> [< 
   | `Shmem of peer_uid option * peer_uid * (t -> 'a Lwt.t)
   | `TCPv4 of ipv4_src option * ipv4_dst * (t -> 'a Lwt.t)
  ] -> 'a Lwt.t

val listen :
  Manager.t -> [< 
   | `Shmem of peer_uid * (peer_uid -> t -> unit Lwt.t)
   | `TCPv4 of ipv4_src * (ipv4_dst -> t -> unit Lwt.t)
  ] -> unit Lwt.t

