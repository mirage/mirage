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

(** Memory allocation. *)

type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
(** Type of memory blocks. *)

val get : int -> t
(** [get n] allocates and returns a memory block of [n] pages. If
    there is not enough memory, the unikernel will terminate. *)

val get_order : int -> t
(** [get_order i] is [get (1 lsl i)]. *)

val pages : int -> t list
(** [pages n] allocates a memory block of [n] pages and return the the
    list of pages allocated. *)

val pages_order : int -> t list
(** [pages_order i] is [pages (1 lsl i)]. *)

val length : t -> int
(** [length t] is the size of [t], in bytes. *)

val to_cstruct : t -> Cstruct.t
val to_string : t -> string

val to_pages : t -> t list
(** [to_pages t] is a list of [size] memory blocks of one page each,
    where [size] is the size of [t] in pages. *)

val string_blit : string -> int -> t -> int -> int -> unit
(** [string_blit src srcoff dst dstoff len] copies [len] bytes from
    string [src], starting at byte number [srcoff], to memory block
    [dst], starting at byte number dstoff. *)

val blit : t -> t -> unit
(** [blit t1 t2] is the same as {!Bigarray.Array1.blit}. *)

val round_to_page_size : int -> int
(** [round_to_page_size n] returns the number of bytes that will be
    allocated for storing [n] bytes in memory *)
