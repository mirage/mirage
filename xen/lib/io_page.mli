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

(** Memory allocation.

    Memory deallocation is normally automatic and handled by the
    GC. In specific cases where you can ensure that a block can be
    safely deallocated, you can call [recycle] on it instead of
    leaving it to the GC. This will enable a much faster reallocation,
    and can be very useful to handle ICMP/ARP floods that would
    otherwise put the GC into pressure.

*)

type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t
(** Type of memory blocks. *)

val get : int -> t
(** [get n] allocates and returns a zeroed memory block of [n]
    pages. If there is not enough memory, the unikernel will
    terminate. *)

val get_order : int -> t
(** [get_order i] is [get (1 lsl i)]. *)

val pages : int -> t list
(** [pages n] allocates n zeroed memory pages and return them. *)

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

val recycle : t -> unit
(** [recycle block] puts [block] into the stack of reusable pages if
    the size of [block] is exactly one page, or raise
    [Invalid_argument] otherwise. *)
