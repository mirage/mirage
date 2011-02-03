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

module Prettyprint : sig
  val hexdump : string -> string
end

module Raw : sig
  type t
  val alloc : unit -> t
end

module View : sig
  type t
  type 'a data = [ `Frag of t | `None | `Str of string | `Sub of t -> 'a ]
  type byte = int
  type uint16 = int

  val t : ?off:int -> Raw.t -> int -> t
  val length : t -> int
  val sub : t -> int -> int -> t
  val copy : t -> t
  val off : t -> int
  val set_string : t -> int -> string -> unit
  val set_byte : t -> int -> byte -> unit
  val set_uint16_be : t -> int -> uint16 -> unit
  val set_uint32_be : t -> int -> int32 -> unit
  val set_uint64_be : t -> int -> int64 -> unit
  val set_view : t -> int -> t -> unit
  val to_char : t -> int -> char
  val to_string : t -> int -> int -> string
  val to_byte : t -> int -> byte
  val to_uint16_be : t -> int -> uint16
  val to_uint32_be : t -> int -> int32
  val to_uint64_be : t -> int -> int64
  val seek : t -> int -> unit
  val ones_complement_checksum : t -> int -> int32 -> int
end
