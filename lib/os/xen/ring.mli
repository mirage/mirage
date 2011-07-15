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

val alloc: int -> (Gnttab.r * Bitstring.t) Lwt.t
type sring

val init : Bitstring.t -> idx_size:int -> name:string -> sring

module Front : sig
  type 'a t
  val init : sring:sring -> 'a t
  val slot : 'a t -> int -> Bitstring.t
  val nr_ents : 'a t -> int
  val get_free_requests : 'a t -> int
  val is_ring_full : 'a t -> bool
  val has_unconsumed_responses : 'a t -> bool
  val push_requests : 'a t -> unit
  val push_requests_and_check_notify : 'a t -> bool
  val check_for_responses : 'a t -> bool
  val next_req_id : 'a t -> int
  val ack_responses : 'a t -> (Bitstring.t -> unit) -> unit
  val poll : 'a t -> (Bitstring.t -> (int * 'a)) -> unit
  val push_request_and_wait : 'a t -> (Bitstring.t -> int) -> 'a Lwt.t
end

module Console : sig
  type t
  external unsafe_write : t -> string -> int -> int = "caml_console_ring_write"
  external unsafe_read : t -> string -> int -> int = "caml_console_ring_read"
  val alloc_initial : unit -> Gnttab.r * t
end

module Xenstore : sig
  type t
  external unsafe_write : t -> string -> int -> int = "caml_xenstore_ring_write"
  external unsafe_read : t -> string -> int -> int = "caml_xenstore_ring_read"
  val alloc_initial : unit -> Gnttab.r * t
end
