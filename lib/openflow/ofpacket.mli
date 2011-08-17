(*
 * Copyright (c) 2011 Richard Mortier <mort@cantab.net>
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

exception Unparsable of string * Bitstring.bitstring

val ( |> ) : 'a -> ('a -> 'b) -> 'b
val ( >> ) : ('a -> 'b) -> ('b -> 'c) -> 'a -> 'c
val ( ||> ) : 'a list -> ('a -> 'b) -> 'b list
val ( +++ ) : int32 -> int32 -> int32
val ( &&& ) : int32 -> int32 -> int32
val ( ||| ) : int32 -> int32 -> int32
val ( ^^^ ) : int32 -> int32 -> int32
val ( <<< ) : int32 -> int -> int32
val ( >>> ) : int32 -> int -> int32
val join : string -> string list -> string
val stop : 'a * 'b -> 'a
type int16 = int
type ipv4 = int32
val ipv4_to_string : int32 -> string
type byte = char
val byte : int -> byte
val int_of_byte : char -> int
val int32_of_byte : char -> int32
val int32_of_int : int -> int32
type bytes = string
val bytes_to_hex_string : char array -> string array
val bytes_of_bitstring : Bitstring.bitstring -> string
val ipv4_addr_of_bytes : string -> int32
