(*
 * Copyright (c) 2011-2012 Anil Madhavapeddy <anil@recoil.org>
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

(** Module implementing a memory pool (fixed 4096 bytes block
    allocation) *)

(** Type of a memory page. *)
type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

(** Get a page from the memory pool, allocating memory if needed. *)
val get : unit -> t

(** [gen_n n] gets [n] pages from the memory pool, allocating memory
    if needed. *)
val get_n : int -> t list

(** Create a Cstruct.t value out of a memory page. *)
val to_cstruct : t -> Cstruct.t

(** [length p] gives the length of page [p], in bytes.*)
val length : t -> int

(** [round_to_page_size n] returns the number of bytes that will be
    allocated for storing [n] bytes in memory *)
val round_to_page_size : int -> int
