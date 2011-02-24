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

val input: t -> Mpl.Ipv4.o -> Mpl.Tcp.o -> unit Lwt.t
val listen: t -> int -> ((ipv4_addr * int) -> pcb -> unit Lwt.t) -> unit Lwt.t
val create: Ipv4.t -> t * unit Lwt.t

val close: pcb -> unit Lwt.t

(* Blocking read for a segment *)
val read: pcb -> OS.Istring.t option Lwt.t

(* Low-level write interface that lets the application
   decide on a write strategy *)
val write_available: pcb -> int32
val write_wait_for: pcb -> int32 -> unit Lwt.t
val write: pcb -> unit OS.Istring.View.data -> unit Lwt.t
