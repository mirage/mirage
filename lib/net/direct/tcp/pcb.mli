(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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
type pcb
type listener
type connection = (pcb * unit Lwt.t) 

val input: t -> src:ipv4_addr -> dst:ipv4_addr -> Bitstring.t -> unit Lwt.t

val connect: t -> dest_ip:ipv4_addr -> dest_port:int -> connection option Lwt.t

val listen: t -> int -> (connection Lwt_stream.t * listener)
val closelistener: listener -> unit

val close: pcb -> unit Lwt.t

val get_dest: pcb -> (ipv4_addr * int)

(* Blocking read for a segment *)
val read: pcb -> Bitstring.t option Lwt.t

(* Low-level write interface that lets the application
   decide on a write strategy *)
val write_available: pcb -> int
val write_wait_for: pcb -> int -> unit Lwt.t
(* Write a segment *)
val write: pcb -> Bitstring.t -> unit Lwt.t
(* Write a segment without using Nagle's algorithm*)
val write_nodelay: pcb -> Bitstring.t -> unit Lwt.t

val create: Ipv4.t -> t * unit Lwt.t
val tcpstats: t -> unit
