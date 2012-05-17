(*
 * Copyright (c) 2012 Anil Madhavapeddy <anil@recoil.org>
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

type buf = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

type uint8 = int
type uint16 = int
type uint32 = int32
type uint64 = int64

val get_uint8 : buf -> int -> uint8
val set_uint8 : buf -> int -> uint8 -> unit

val sub_buffer : buf -> int -> int -> buf
val copy_buffer : buf -> int -> int -> string

val blit_buffer : buf -> int -> buf -> int -> int -> unit
val set_buffer : string -> int -> buf -> int -> int -> unit

module BE : sig
  val get_uint16 : buf -> int -> uint16
  val get_uint32 : buf -> int -> uint32
  val get_uint64 : buf -> int -> uint64

  val set_uint16 : buf -> int -> uint16 -> unit
  val set_uint32 : buf -> int -> uint32 -> unit
  val set_uint64 : buf -> int -> uint64 -> unit
end

module LE : sig
  val get_uint16 : buf -> int -> uint16
  val get_uint32 : buf -> int -> uint32
  val get_uint64 : buf -> int -> uint64

  val set_uint16 : buf -> int -> uint16 -> unit
  val set_uint32 : buf -> int -> uint32 -> unit
  val set_uint64 : buf -> int -> uint64 -> unit
end

val len : buf -> int
val base_offset : buf -> int
val sub : buf -> int -> int -> buf
val shift : buf -> int -> buf
val split : buf -> int -> buf * buf
val to_string : buf -> string

val hexdump : buf -> unit

val iter: int -> (buf -> int) -> buf -> (unit -> (buf * buf) option)
