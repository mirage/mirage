(* Bitstring library.
 * Copyright (C) 2008 Red Hat Inc., Richard W.M. Jones
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version,
 * with the OCaml linking exception described in COPYING.LIB.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * $Id: bitstring.ml 172 2008-10-06 08:43:14Z richard.wm.jones $
 *)

open Printf

include Bitstring_types
include Bitstring_config

(* Enable runtime debug messages.  Must also have been enabled
 * in pa_bitstring.ml.
 *)
let debug = ref false

(* Exceptions. *)
exception Construct_failure of string * string * int * int

(* A bitstring is simply the data itself (as a string), and the
 * bitoffset and the bitlength within the string.  Note offset/length
 * are counted in bits, not bytes.
 *)
type bitstring = string * int * int

type t = bitstring

(* Functions to create and load bitstrings. *)
let empty_bitstring = "", 0, 0

let make_bitstring len c =
  if len >= 0 then String.make ((len+7) lsr 3) c, 0, len
  else
    invalid_arg (
      sprintf "make_bitstring/create_bitstring: len %d < 0" len
    )

let create_bitstring len = make_bitstring len '\000'

let zeroes_bitstring = create_bitstring

let ones_bitstring len = make_bitstring len '\xff'

let bitstring_of_string str = str, 0, String.length str lsl 3

let bitstring_of_chan chan =
  let tmpsize = 16384 in
  let buf = Buffer.create tmpsize in
  let tmp = String.create tmpsize in
  let n = ref 0 in
  while n := input chan tmp 0 tmpsize; !n > 0 do
    Buffer.add_substring buf tmp 0 !n;
  done;
  Buffer.contents buf, 0, Buffer.length buf lsl 3

let bitstring_of_chan_max chan max =
  let tmpsize = 16384 in
  let buf = Buffer.create tmpsize in
  let tmp = String.create tmpsize in
  let len = ref 0 in
  let rec loop () =
    if !len < max then (
      let r = min tmpsize (max - !len) in
      let n = input chan tmp 0 r in
      if n > 0 then (
	Buffer.add_substring buf tmp 0 n;
	len := !len + n;
	loop ()
      )
    )
  in
  loop ();
  Buffer.contents buf, 0, !len lsl 3

let bitstring_length (_, _, len) = len

let bitstring_is_byte_aligned (_, off, len) =
  off mod 8 = 0 && (len mod 8 = 0)

let bitstring_write ((src_s, src_off, src_len) as src) offset_bytes
  ((dest_s, dest_off, dest_len) as dest) =
  (* We don't expect to run off the end of the target bitstring *)
  assert (dest_len - offset_bytes * 8 - src_len >= 0);
  assert (bitstring_is_byte_aligned src);
  assert (bitstring_is_byte_aligned dest);
  String.blit src_s (src_off / 8) dest_s (dest_off / 8 + offset_bytes)
    (src_len / 8)

let subbitstring (data, off, len) off' len' =
  let off = off + off' in
  if len < off' + len' then invalid_arg "subbitstring";
  (data, off, len')

let dropbits n (data, off, len) =
  let off = off + n in
  let len = len - n in
  if len < 0 then invalid_arg "dropbits";
  (data, off, len)

let takebits n (data, off, len) =
  if len < n then invalid_arg "takebits";
  (data, off, n)

let bitstring_chop n bits =
  let rec inner acc bits =
    if bitstring_length bits <= n then bits :: acc
    else inner (takebits n bits :: acc) (dropbits n bits) in
  List.rev (inner [] bits)

let bitstring_clip (s_s, s_off, s_len) offset length =
  let s_end = s_off + s_len in
  let the_end = offset + length in
  let offset' = max s_off offset in
  let end' = min s_end the_end in
  let length' = max 0 (end' - offset') in
  s_s, offset', length'


(*----------------------------------------------------------------------*)
(* Bitwise functions.
 *
 * We try to isolate all bitwise functions within these modules.
 *)

module I = struct
  (* Bitwise operations on ints.  Note that we assume int <= 31 bits. *)
  external (<<<) : int -> int -> int = "%lslint"
  external (>>>) : int -> int -> int = "%lsrint"
  external to_int : int -> int = "%identity"
  let zero = 0
  let one = 1
  let minus_one = -1
  let ff = 0xff

  (* Create a mask 0-31 bits wide. *)
  let mask bits =
    if bits < 30 then
      (one <<< bits) - 1
    else if bits = 30 then
      max_int
    else if bits = 31 then
      minus_one
    else
      invalid_arg "Bitstring.I.mask"

  (* Byte swap an int of a given size. *)
  let byteswap v bits =
    if bits <= 8 then v
    else if bits <= 16 then (
      let shift = bits-8 in
      let v1 = v >>> shift in
      let v2 = ((v land (mask shift)) <<< 8) in
      v2 lor v1
    ) else if bits <= 24 then (
      let shift = bits - 16 in
      let v1 = v >>> (8+shift) in
      let v2 = ((v >>> shift) land ff) <<< 8 in
      let v3 = (v land (mask shift)) <<< 16 in
      v3 lor v2 lor v1
    ) else (
      let shift = bits - 24 in
      let v1 = v >>> (16+shift) in
      let v2 = ((v >>> (8+shift)) land ff) <<< 8 in
      let v3 = ((v >>> shift) land ff) <<< 16 in
      let v4 = (v land (mask shift)) <<< 24 in
      v4 lor v3 lor v2 lor v1
    )

  (* Check a value is in range 0 .. 2^bits-1. *)
  let range_unsigned v bits =
    let mask = lnot (mask bits) in
    (v land mask) = zero

  (* Call function g on the top bits, then f on each full byte
   * (big endian - so start at top).
   *)
  let rec map_bytes_be g f v bits =
    if bits >= 8 then (
      map_bytes_be g f (v >>> 8) (bits-8);
      let lsb = v land ff in
      f (to_int lsb)
    ) else if bits > 0 then (
      let lsb = v land (mask bits) in
      g (to_int lsb) bits
    )

  (* Call function g on the top bits, then f on each full byte
   * (little endian - so start at root).
   *)
  let rec map_bytes_le g f v bits =
    if bits >= 8 then (
      let lsb = v land ff in
      f (to_int lsb);
      map_bytes_le g f (v >>> 8) (bits-8)
    ) else if bits > 0 then (
      let lsb = v land (mask bits) in
      g (to_int lsb) bits
    )
end

module I32 = struct
  (* Bitwise operations on int32s.  Note we try to keep it as similar
   * as possible to the I module above, to make it easier to track
   * down bugs.
   *)
  let (<<<) = Int32.shift_left
  let (>>>) = Int32.shift_right_logical
  let (land) = Int32.logand
  let (lor) = Int32.logor
  let lnot = Int32.lognot
  let pred = Int32.pred
  let max_int = Int32.max_int
  let to_int = Int32.to_int
  let zero = Int32.zero
  let one = Int32.one
  let minus_one = Int32.minus_one
  let ff = 0xff_l

  (* Create a mask so many bits wide. *)
  let mask bits =
    if bits < 31 then
      pred (one <<< bits)
    else if bits = 31 then
      max_int
    else if bits = 32 then
      minus_one
    else
      invalid_arg "Bitstring.I32.mask"

  (* Byte swap an int of a given size. *)
  let byteswap v bits =
    if bits <= 8 then v
    else if bits <= 16 then (
      let shift = bits-8 in
      let v1 = v >>> shift in
      let v2 = (v land (mask shift)) <<< 8 in
      v2 lor v1
    ) else if bits <= 24 then (
      let shift = bits - 16 in
      let v1 = v >>> (8+shift) in
      let v2 = ((v >>> shift) land ff) <<< 8 in
      let v3 = (v land (mask shift)) <<< 16 in
      v3 lor v2 lor v1
    ) else (
      let shift = bits - 24 in
      let v1 = v >>> (16+shift) in
      let v2 = ((v >>> (8+shift)) land ff) <<< 8 in
      let v3 = ((v >>> shift) land ff) <<< 16 in
      let v4 = (v land (mask shift)) <<< 24 in
      v4 lor v3 lor v2 lor v1
    )

  (* Check a value is in range 0 .. 2^bits-1. *)
  let range_unsigned v bits =
    let mask = lnot (mask bits) in
    (v land mask) = zero

  (* Call function g on the top bits, then f on each full byte
   * (big endian - so start at top).
   *)
  let rec map_bytes_be g f v bits =
    if bits >= 8 then (
      map_bytes_be g f (v >>> 8) (bits-8);
      let lsb = v land ff in
      f (to_int lsb)
    ) else if bits > 0 then (
      let lsb = v land (mask bits) in
      g (to_int lsb) bits
    )

  (* Call function g on the top bits, then f on each full byte
   * (little endian - so start at root).
   *)
  let rec map_bytes_le g f v bits =
    if bits >= 8 then (
      let lsb = v land ff in
      f (to_int lsb);
      map_bytes_le g f (v >>> 8) (bits-8)
    ) else if bits > 0 then (
      let lsb = v land (mask bits) in
      g (to_int lsb) bits
    )
end

module I64 = struct
  (* Bitwise operations on int64s.  Note we try to keep it as similar
   * as possible to the I/I32 modules above, to make it easier to track
   * down bugs.
   *)
  let (<<<) = Int64.shift_left
  let (>>>) = Int64.shift_right_logical
  let (land) = Int64.logand
  let (lor) = Int64.logor
  let lnot = Int64.lognot
  let pred = Int64.pred
  let max_int = Int64.max_int
  let to_int = Int64.to_int
  let zero = Int64.zero
  let one = Int64.one
  let minus_one = Int64.minus_one
  let ff = 0xff_L

  (* Create a mask so many bits wide. *)
  let mask bits =
    if bits < 63 then
      pred (one <<< bits)
    else if bits = 63 then
      max_int
    else if bits = 64 then
      minus_one
    else
      invalid_arg "Bitstring.I64.mask"

  (* Byte swap an int of a given size. *)
  (* let byteswap v bits = *)

  (* Check a value is in range 0 .. 2^bits-1. *)
  let range_unsigned v bits =
    let mask = lnot (mask bits) in
    (v land mask) = zero

  (* Call function g on the top bits, then f on each full byte
   * (big endian - so start at top).
   *)
  let rec map_bytes_be g f v bits =
    if bits >= 8 then (
      map_bytes_be g f (v >>> 8) (bits-8);
      let lsb = v land ff in
      f (to_int lsb)
    ) else if bits > 0 then (
      let lsb = v land (mask bits) in
      g (to_int lsb) bits
    )

  (* Call function g on the top bits, then f on each full byte
   * (little endian - so start at root).
   *)
  let rec map_bytes_le g f v bits =
    if bits >= 8 then (
      let lsb = v land ff in
      f (to_int lsb);
      map_bytes_le g f (v >>> 8) (bits-8)
    ) else if bits > 0 then (
      let lsb = v land (mask bits) in
      g (to_int lsb) bits
    )
end

(*----------------------------------------------------------------------*)
(* Extraction functions.
 *
 * NB: internal functions, called from the generated macros, and
 * the parameters should have been checked for sanity already).
 *)

(* Extract and convert to numeric.  A single bit is returned as
 * a boolean.  There are no endianness or signedness considerations.
 *)
let extract_bit data off len _ =	(* final param is always 1 *)
  let byteoff = off lsr 3 in
  let bitmask = 1 lsl (7 - (off land 7)) in
  let b = Char.code data.[byteoff] land bitmask <> 0 in
  b (*, off+1, len-1*)

(* Returns 8 bit unsigned aligned bytes from the string.
 * If the string ends then this returns 0's.
 *)
let _get_byte data byteoff strlen =
  if strlen > byteoff then Char.code data.[byteoff] else 0
let _get_byte32 data byteoff strlen =
  if strlen > byteoff then Int32.of_int (Char.code data.[byteoff]) else 0l
let _get_byte64 data byteoff strlen =
  if strlen > byteoff then Int64.of_int (Char.code data.[byteoff]) else 0L

(* Extract [2..8] bits.  Because the result fits into a single
 * byte we don't have to worry about endianness, only signedness.
 *)
let extract_char_unsigned data off len flen =
  let byteoff = off lsr 3 in

  (* Optimize the common (byte-aligned) case. *)
  if off land 7 = 0 then (
    let byte = Char.code data.[byteoff] in
    byte lsr (8 - flen) (*, off+flen, len-flen*)
  ) else (
    (* Extract the 16 bits at byteoff and byteoff+1 (note that the
     * second byte might not exist in the original string).
     *)
    let strlen = String.length data in

    let word =
      (_get_byte data byteoff strlen lsl 8) +
	_get_byte data (byteoff+1) strlen in

    (* Mask off the top bits. *)
    let bitmask = (1 lsl (16 - (off land 7))) - 1 in
    let word = word land bitmask in
    (* Shift right to get rid of the bottom bits. *)
    let shift = 16 - ((off land 7) + flen) in
    let word = word lsr shift in

    word (*, off+flen, len-flen*)
  )

(* Extract [9..31] bits.  We have to consider endianness and signedness. *)
let extract_int_be_unsigned data off len flen =
  let byteoff = off lsr 3 in

  let strlen = String.length data in

  let word =
    (* Optimize the common (byte-aligned) case. *)
    if off land 7 = 0 then (
      let word =
	(_get_byte data byteoff strlen lsl 23) +
	  (_get_byte data (byteoff+1) strlen lsl 15) +
	  (_get_byte data (byteoff+2) strlen lsl 7) +
	  (_get_byte data (byteoff+3) strlen lsr 1) in
      word lsr (31 - flen)
    ) else if flen <= 24 then (
      (* Extract the 31 bits at byteoff .. byteoff+3. *)
      let word =
	(_get_byte data byteoff strlen lsl 23) +
	  (_get_byte data (byteoff+1) strlen lsl 15) +
	  (_get_byte data (byteoff+2) strlen lsl 7) +
	  (_get_byte data (byteoff+3) strlen lsr 1) in
      (* Mask off the top bits. *)
      let bitmask = (1 lsl (31 - (off land 7))) - 1 in
      let word = word land bitmask in
      (* Shift right to get rid of the bottom bits. *)
      let shift = 31 - ((off land 7) + flen) in
      word lsr shift
    ) else (
      (* Extract the next 31 bits, slow method. *)
      let word =
	let c0 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c1 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c2 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c3 = extract_char_unsigned data off len 7 in
	(c0 lsl 23) + (c1 lsl 15) + (c2 lsl 7) + c3 in
      word lsr (31 - flen)
    ) in
  word (*, off+flen, len-flen*)

let extract_int_le_unsigned data off len flen =
  let v = extract_int_be_unsigned data off len flen in
  let v = I.byteswap v flen in
  v

let extract_int_ne_unsigned =
  if nativeendian = BigEndian
  then extract_int_be_unsigned
  else extract_int_le_unsigned

let extract_int_ee_unsigned = function
  | BigEndian -> extract_int_be_unsigned
  | LittleEndian -> extract_int_le_unsigned
  | NativeEndian -> extract_int_ne_unsigned

let _make_int32_be c0 c1 c2 c3 =
  Int32.logor
    (Int32.logor
       (Int32.logor
	  (Int32.shift_left c0 24)
	  (Int32.shift_left c1 16))
       (Int32.shift_left c2 8))
    c3

let _make_int32_le c0 c1 c2 c3 =
  Int32.logor
    (Int32.logor
       (Int32.logor
	  (Int32.shift_left c3 24)
	  (Int32.shift_left c2 16))
       (Int32.shift_left c1 8))
    c0

(* Extract exactly 32 bits.  We have to consider endianness and signedness. *)
let extract_int32_be_unsigned data off len flen =
  let byteoff = off lsr 3 in

  let strlen = String.length data in

  let word =
    (* Optimize the common (byte-aligned) case. *)
    if off land 7 = 0 then (
      let word =
	let c0 = _get_byte32 data byteoff strlen in
	let c1 = _get_byte32 data (byteoff+1) strlen in
	let c2 = _get_byte32 data (byteoff+2) strlen in
	let c3 = _get_byte32 data (byteoff+3) strlen in
	_make_int32_be c0 c1 c2 c3 in
      Int32.shift_right_logical word (32 - flen)
    ) else (
      (* Extract the next 32 bits, slow method. *)
      let word =
	let c0 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c1 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c2 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c3 = extract_char_unsigned data off len 8 in
	let c0 = Int32.of_int c0 in
	let c1 = Int32.of_int c1 in
	let c2 = Int32.of_int c2 in
	let c3 = Int32.of_int c3 in
	_make_int32_be c0 c1 c2 c3 in
      Int32.shift_right_logical word (32 - flen)
    ) in
  word (*, off+flen, len-flen*)

let extract_int32_le_unsigned data off len flen =
  let v = extract_int32_be_unsigned data off len flen in
  let v = I32.byteswap v flen in
  v

let extract_int32_ne_unsigned =
  if nativeendian = BigEndian
  then extract_int32_be_unsigned
  else extract_int32_le_unsigned

let extract_int32_ee_unsigned = function
  | BigEndian -> extract_int32_be_unsigned
  | LittleEndian -> extract_int32_le_unsigned
  | NativeEndian -> extract_int32_ne_unsigned

let _make_int64_be c0 c1 c2 c3 c4 c5 c6 c7 =
  Int64.logor
    (Int64.logor
       (Int64.logor
	  (Int64.logor
	     (Int64.logor
		(Int64.logor
		   (Int64.logor
		      (Int64.shift_left c0 56)
		      (Int64.shift_left c1 48))
		   (Int64.shift_left c2 40))
		(Int64.shift_left c3 32))
	     (Int64.shift_left c4 24))
	  (Int64.shift_left c5 16))
       (Int64.shift_left c6 8))
    c7

let _make_int64_le c0 c1 c2 c3 c4 c5 c6 c7 =
  _make_int64_be c7 c6 c5 c4 c3 c2 c1 c0

(* Extract [1..64] bits.  We have to consider endianness and signedness. *)
let extract_int64_be_unsigned data off len flen =
  let byteoff = off lsr 3 in

  let strlen = String.length data in

  let word =
    (* Optimize the common (byte-aligned) case. *)
    if off land 7 = 0 then (
      let word =
	let c0 = _get_byte64 data byteoff strlen in
	let c1 = _get_byte64 data (byteoff+1) strlen in
	let c2 = _get_byte64 data (byteoff+2) strlen in
	let c3 = _get_byte64 data (byteoff+3) strlen in
	let c4 = _get_byte64 data (byteoff+4) strlen in
	let c5 = _get_byte64 data (byteoff+5) strlen in
	let c6 = _get_byte64 data (byteoff+6) strlen in
	let c7 = _get_byte64 data (byteoff+7) strlen in
	_make_int64_be c0 c1 c2 c3 c4 c5 c6 c7 in
      Int64.shift_right_logical word (64 - flen)
    ) else (
      (* Extract the next 64 bits, slow method. *)
      let word =
	let c0 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c1 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c2 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c3 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c4 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c5 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c6 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c7 = extract_char_unsigned data off len 8 in
	let c0 = Int64.of_int c0 in
	let c1 = Int64.of_int c1 in
	let c2 = Int64.of_int c2 in
	let c3 = Int64.of_int c3 in
	let c4 = Int64.of_int c4 in
	let c5 = Int64.of_int c5 in
	let c6 = Int64.of_int c6 in
	let c7 = Int64.of_int c7 in
	_make_int64_be c0 c1 c2 c3 c4 c5 c6 c7 in
      Int64.shift_right_logical word (64 - flen)
    ) in
  word (*, off+flen, len-flen*)

let extract_int64_le_unsigned data off len flen =
  let byteoff = off lsr 3 in

  let strlen = String.length data in

  let word =
    (* Optimize the common (byte-aligned) case. *)
    if off land 7 = 0 then (
      let word =
	let c0 = _get_byte64 data byteoff strlen in
	let c1 = _get_byte64 data (byteoff+1) strlen in
	let c2 = _get_byte64 data (byteoff+2) strlen in
	let c3 = _get_byte64 data (byteoff+3) strlen in
	let c4 = _get_byte64 data (byteoff+4) strlen in
	let c5 = _get_byte64 data (byteoff+5) strlen in
	let c6 = _get_byte64 data (byteoff+6) strlen in
	let c7 = _get_byte64 data (byteoff+7) strlen in
	_make_int64_le c0 c1 c2 c3 c4 c5 c6 c7 in
      Int64.logand word (I64.mask flen)
    ) else (
      (* Extract the next 64 bits, slow method. *)
      let word =
	let c0 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c1 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c2 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c3 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c4 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c5 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c6 = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	let c7 = extract_char_unsigned data off len 8 in
	let c0 = Int64.of_int c0 in
	let c1 = Int64.of_int c1 in
	let c2 = Int64.of_int c2 in
	let c3 = Int64.of_int c3 in
	let c4 = Int64.of_int c4 in
	let c5 = Int64.of_int c5 in
	let c6 = Int64.of_int c6 in
	let c7 = Int64.of_int c7 in
	_make_int64_le c0 c1 c2 c3 c4 c5 c6 c7 in
      Int64.logand word (I64.mask flen)
    ) in
  word (*, off+flen, len-flen*)

let extract_int64_ne_unsigned =
  if nativeendian = BigEndian
  then extract_int64_be_unsigned
  else extract_int64_le_unsigned

let extract_int64_ee_unsigned = function
  | BigEndian -> extract_int64_be_unsigned
  | LittleEndian -> extract_int64_le_unsigned
  | NativeEndian -> extract_int64_ne_unsigned

external extract_fastpath_int16_be_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_be_unsigned" "noalloc"

external extract_fastpath_int16_le_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_le_unsigned" "noalloc"

external extract_fastpath_int16_ne_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_ne_unsigned" "noalloc"

external extract_fastpath_int16_be_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_be_signed" "noalloc"

external extract_fastpath_int16_le_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_le_signed" "noalloc"

external extract_fastpath_int16_ne_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int16_ne_signed" "noalloc"

(*
external extract_fastpath_int24_be_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_be_unsigned" "noalloc"

external extract_fastpath_int24_le_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_le_unsigned" "noalloc"

external extract_fastpath_int24_ne_unsigned : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_ne_unsigned" "noalloc"

external extract_fastpath_int24_be_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_be_signed" "noalloc"

external extract_fastpath_int24_le_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_le_signed" "noalloc"

external extract_fastpath_int24_ne_signed : string -> int -> int = "ocaml_bitstring_extract_fastpath_int24_ne_signed" "noalloc"
*)

external extract_fastpath_int32_be_unsigned : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_be_unsigned" "noalloc"

external extract_fastpath_int32_le_unsigned : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_le_unsigned" "noalloc"

external extract_fastpath_int32_ne_unsigned : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_ne_unsigned" "noalloc"

external extract_fastpath_int32_be_signed : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_be_signed" "noalloc"

external extract_fastpath_int32_le_signed : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_le_signed" "noalloc"

external extract_fastpath_int32_ne_signed : string -> int -> int32 -> int32 = "ocaml_bitstring_extract_fastpath_int32_ne_signed" "noalloc"

(*
external extract_fastpath_int40_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_be_unsigned" "noalloc"

external extract_fastpath_int40_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_le_unsigned" "noalloc"

external extract_fastpath_int40_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_ne_unsigned" "noalloc"

external extract_fastpath_int40_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_be_signed" "noalloc"

external extract_fastpath_int40_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_le_signed" "noalloc"

external extract_fastpath_int40_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int40_ne_signed" "noalloc"

external extract_fastpath_int48_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_be_unsigned" "noalloc"

external extract_fastpath_int48_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_le_unsigned" "noalloc"

external extract_fastpath_int48_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_ne_unsigned" "noalloc"

external extract_fastpath_int48_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_be_signed" "noalloc"

external extract_fastpath_int48_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_le_signed" "noalloc"

external extract_fastpath_int48_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int48_ne_signed" "noalloc"

external extract_fastpath_int56_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_be_unsigned" "noalloc"

external extract_fastpath_int56_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_le_unsigned" "noalloc"

external extract_fastpath_int56_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_ne_unsigned" "noalloc"

external extract_fastpath_int56_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_be_signed" "noalloc"

external extract_fastpath_int56_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_le_signed" "noalloc"

external extract_fastpath_int56_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int56_ne_signed" "noalloc"
*)

external extract_fastpath_int64_be_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_be_unsigned" "noalloc"

external extract_fastpath_int64_le_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_le_unsigned" "noalloc"

external extract_fastpath_int64_ne_unsigned : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_ne_unsigned" "noalloc"

external extract_fastpath_int64_be_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_be_signed" "noalloc"

external extract_fastpath_int64_le_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_le_signed" "noalloc"

external extract_fastpath_int64_ne_signed : string -> int -> int64 -> int64 = "ocaml_bitstring_extract_fastpath_int64_ne_signed" "noalloc"

(*----------------------------------------------------------------------*)
(* Constructor functions. *)

module Buffer = struct
  type t = {
    buf : Buffer.t;
    mutable len : int;			(* Length in bits. *)
    (* Last byte in the buffer (if len is not aligned).  We store
     * it outside the buffer because buffers aren't mutable.
     *)
    mutable last : int;
  }

  let create () =
    (* XXX We have almost enough information in the generator to
     * choose a good initial size.
     *)
    { buf = Buffer.create 128; len = 0; last = 0 }

  let contents { buf = buf; len = len; last = last } =
    let data =
      if len land 7 = 0 then
	Buffer.contents buf
      else
	Buffer.contents buf ^ (String.make 1 (Char.chr last)) in
    data, 0, len

  (* Add exactly 8 bits. *)
  let add_byte ({ buf = buf; len = len; last = last } as t) byte =
    if byte < 0 || byte > 255 then invalid_arg "Bitstring.Buffer.add_byte";
    let shift = len land 7 in
    if shift = 0 then
      (* Target buffer is byte-aligned. *)
      Buffer.add_char buf (Char.chr byte)
    else (
      (* Target buffer is unaligned.  'last' is meaningful. *)
      let first = byte lsr shift in
      let second = (byte lsl (8 - shift)) land 0xff in
      Buffer.add_char buf (Char.chr (last lor first));
      t.last <- second
    );
    t.len <- t.len + 8

  (* Add exactly 1 bit. *)
  let add_bit ({ buf = buf; len = len; last = last } as t) bit =
    let shift = 7 - (len land 7) in
    if shift > 0 then
      (* Somewhere in the middle of 'last'. *)
      t.last <- last lor ((if bit then 1 else 0) lsl shift)
    else (
      (* Just a single spare bit in 'last'. *)
      let last = last lor if bit then 1 else 0 in
      Buffer.add_char buf (Char.chr last);
      t.last <- 0
    );
    t.len <- len + 1

  (* Add a small number of bits (definitely < 8).  This uses a loop
   * to call add_bit so it's slow.
   *)
  let _add_bits t c slen =
    if slen < 1 || slen >= 8 then invalid_arg "Bitstring.Buffer._add_bits";
    for i = slen-1 downto 0 do
      let bit = c land (1 lsl i) <> 0 in
      add_bit t bit
    done

  let add_bits ({ buf = buf; len = len } as t) str slen =
    if slen > 0 then (
      if len land 7 = 0 then (
	if slen land 7 = 0 then
	  (* Common case - everything is byte-aligned. *)
	  Buffer.add_substring buf str 0 (slen lsr 3)
	else (
	  (* Target buffer is aligned.  Copy whole bytes then leave the
	   * remaining bits in last.
	   *)
	  let slenbytes = slen lsr 3 in
	  if slenbytes > 0 then Buffer.add_substring buf str 0 slenbytes;
	  let last = Char.code str.[slenbytes] in (* last char *)
	  let mask = 0xff lsl (8 - (slen land 7)) in
	  t.last <- last land mask
	);
	t.len <- len + slen
      ) else (
	(* Target buffer is unaligned.  Copy whole bytes using
	 * add_byte which knows how to deal with an unaligned
	 * target buffer, then call add_bit for the remaining < 8 bits.
	 *
	 * XXX This is going to be dog-slow.
	 *)
	let slenbytes = slen lsr 3 in
	for i = 0 to slenbytes-1 do
	  let byte = Char.code str.[i] in
	  add_byte t byte
	done;
	let bitsleft = slen - (slenbytes lsl 3) in
	if bitsleft > 0 then (
	  let c = Char.code str.[slenbytes] in
	  for i = 0 to bitsleft - 1 do
	    let bit = c land (0x80 lsr i) <> 0 in
	    add_bit t bit
	  done
	)
      );
    )
end

(* Construct a single bit. *)
let construct_bit buf b _ _ =
  Buffer.add_bit buf b

(* Construct a field, flen = [2..8]. *)
let construct_char_unsigned buf v flen exn =
  let max_val = 1 lsl flen in
  if v < 0 || v >= max_val then raise exn;
  if flen = 8 then
    Buffer.add_byte buf v
  else
    Buffer._add_bits buf v flen

(* Construct a field of up to 31 bits. *)
let construct_int_be_unsigned buf v flen exn =
  (* Check value is within range. *)
  if not (I.range_unsigned v flen) then raise exn;
  (* Add the bytes. *)
  I.map_bytes_be (Buffer._add_bits buf) (Buffer.add_byte buf) v flen

(* Construct a field of up to 31 bits. *)
let construct_int_le_unsigned buf v flen exn =
  (* Check value is within range. *)
  if not (I.range_unsigned v flen) then raise exn;
  (* Add the bytes. *)
  I.map_bytes_le (Buffer._add_bits buf) (Buffer.add_byte buf) v flen

let construct_int_ne_unsigned =
  if nativeendian = BigEndian
  then construct_int_be_unsigned
  else construct_int_le_unsigned

let construct_int_ee_unsigned = function
  | BigEndian -> construct_int_be_unsigned
  | LittleEndian -> construct_int_le_unsigned
  | NativeEndian -> construct_int_ne_unsigned

(* Construct a field of exactly 32 bits. *)
let construct_int32_be_unsigned buf v flen _ =
  Buffer.add_byte buf
    (Int32.to_int (Int32.shift_right_logical v 24));
  Buffer.add_byte buf
    (Int32.to_int ((Int32.logand (Int32.shift_right_logical v 16) 0xff_l)));
  Buffer.add_byte buf
    (Int32.to_int ((Int32.logand (Int32.shift_right_logical v 8) 0xff_l)));
  Buffer.add_byte buf
    (Int32.to_int (Int32.logand v 0xff_l))

let construct_int32_le_unsigned buf v flen _ =
  Buffer.add_byte buf
    (Int32.to_int (Int32.logand v 0xff_l));
  Buffer.add_byte buf
    (Int32.to_int ((Int32.logand (Int32.shift_right_logical v 8) 0xff_l)));
  Buffer.add_byte buf
    (Int32.to_int ((Int32.logand (Int32.shift_right_logical v 16) 0xff_l)));
  Buffer.add_byte buf
    (Int32.to_int (Int32.shift_right_logical v 24))

let construct_int32_ne_unsigned =
  if nativeendian = BigEndian
  then construct_int32_be_unsigned
  else construct_int32_le_unsigned

let construct_int32_ee_unsigned = function
  | BigEndian -> construct_int32_be_unsigned
  | LittleEndian -> construct_int32_le_unsigned
  | NativeEndian -> construct_int32_ne_unsigned

(* Construct a field of up to 64 bits. *)
let construct_int64_be_unsigned buf v flen exn =
  (* Check value is within range. *)
  if not (I64.range_unsigned v flen) then raise exn;
  (* Add the bytes. *)
  I64.map_bytes_be (Buffer._add_bits buf) (Buffer.add_byte buf) v flen

(* Construct a field of up to 64 bits. *)
let construct_int64_le_unsigned buf v flen exn =
  (* Check value is within range. *)
  if not (I64.range_unsigned v flen) then raise exn;
  (* Add the bytes. *)
  I64.map_bytes_le (Buffer._add_bits buf) (Buffer.add_byte buf) v flen

let construct_int64_ne_unsigned =
  if nativeendian = BigEndian
  then construct_int64_be_unsigned
  else construct_int64_le_unsigned

let construct_int64_ee_unsigned = function
  | BigEndian -> construct_int64_be_unsigned
  | LittleEndian -> construct_int64_le_unsigned
  | NativeEndian -> construct_int64_ne_unsigned

(* Construct from a string of bytes, exact multiple of 8 bits
 * in length of course.
 *)
let construct_string buf str =
  let len = String.length str in
  Buffer.add_bits buf str (len lsl 3)

(* Construct from a bitstring. *)
let construct_bitstring buf (data, off, len) =
  (* Add individual bits until we get to the next byte boundary of
   * the underlying string.
   *)
  let blen = 7 - ((off + 7) land 7) in
  let blen = min blen len in
  let rec loop off len blen =
    if blen = 0 then (off, len)
    else (
      let b = extract_bit data off len 1
      and off = off + 1 and len = len + 1 in
      Buffer.add_bit buf b;
      loop off len (blen-1)
    )
  in
  let off, len = loop off len blen in
  assert (len = 0 || (off land 7) = 0);

  (* Add the remaining 'len' bits. *)
  let data =
    let off = off lsr 3 in
    (* XXX dangerous allocation *)
    if off = 0 then data
    else String.sub data off (String.length data - off) in

  Buffer.add_bits buf data len

(* Concatenate bitstrings. *)
let concat bs =
  let buf = Buffer.create () in
  List.iter (construct_bitstring buf) bs;
  Buffer.contents buf

(*----------------------------------------------------------------------*)
(* Extract a string from a bitstring. *)
let string_of_bitstring (data, off, len) =
  if off land 7 = 0 && len land 7 = 0 then
    (* Easy case: everything is byte-aligned. *)
    String.sub data (off lsr 3) (len lsr 3)
  else (
    (* Bit-twiddling case. *)
    let strlen = (len + 7) lsr 3 in
    let str = String.make strlen '\000' in
    let rec loop data off len i =
      if len >= 8 then (
	let c = extract_char_unsigned data off len 8
	and off = off + 8 and len = len - 8 in
	str.[i] <- Char.chr c;
	loop data off len (i+1)
      ) else if len > 0 then (
	let c = extract_char_unsigned data off len len in
	str.[i] <- Char.chr (c lsl (8-len))
      )
    in
    loop data off len 0;
    str
  )

(* To channel. *)

let bitstring_to_chan ((data, off, len) as bits) chan =
  (* Fail if the bitstring length isn't a multiple of 8. *)
  if len land 7 <> 0 then invalid_arg "bitstring_to_chan";

  if off land 7 = 0 then
    (* Easy case: string is byte-aligned. *)
    output chan data (off lsr 3) (len lsr 3)
  else (
    (* Bit-twiddling case: reuse string_of_bitstring *)
    let str = string_of_bitstring bits in
    output_string chan str
  )

let bitstring_to_file bits filename =
  let chan = open_out_bin filename in
  try
    bitstring_to_chan bits chan;
    close_out chan
  with exn ->
    close_out chan;
    raise exn

(*----------------------------------------------------------------------*)
(* Comparison. *)
let compare ((data1, off1, len1) as bs1) ((data2, off2, len2) as bs2) =
  (* In the fully-aligned case, this is reduced to string comparison ... *)
  if off1 land 7 = 0 && len1 land 7 = 0 && off2 land 7 = 0 && len2 land 7 = 0
  then (
    (* ... but we have to do that by hand because the bits may
     * not extend to the full length of the underlying string.
     *)
    let off1 = off1 lsr 3 and off2 = off2 lsr 3
    and len1 = len1 lsr 3 and len2 = len2 lsr 3 in
    let rec loop i =
      if i < len1 && i < len2 then (
	let c1 = String.unsafe_get data1 (off1 + i)
	and c2 = String.unsafe_get data2 (off2 + i) in
	let r = compare c1 c2 in
	if r <> 0 then r
	else loop (i+1)
      )
      else len1 - len2
    in
    loop 0
  )
  else (
    (* Slow/unaligned. *)
    let str1 = string_of_bitstring bs1
    and str2 = string_of_bitstring bs2 in
    let r = String.compare str1 str2 in
    if r <> 0 then r else len1 - len2
  )

let equals ((_, _, len1) as bs1) ((_, _, len2) as bs2) =
  if len1 <> len2 then false
  else if bs1 = bs2 then true
  else 0 = compare bs1 bs2

(*----------------------------------------------------------------------*)
(* Bit get/set functions. *)

let index_out_of_bounds () = invalid_arg "index out of bounds"

let put (data, off, len) n v =
  if n < 0 || n >= len then index_out_of_bounds ()
  else (
    let i = off+n in
    let si = i lsr 3 and mask = 0x80 lsr (i land 7) in
    let c = Char.code data.[si] in
    let c = if v <> 0 then c lor mask else c land (lnot mask) in
    data.[si] <- Char.unsafe_chr c
  )

let set bits n = put bits n 1

let clear bits n = put bits n 0

let get (data, off, len) n =
  if n < 0 || n >= len then index_out_of_bounds ()
  else (
    let i = off+n in
    let si = i lsr 3 and mask = 0x80 lsr (i land 7) in
    let c = Char.code data.[si] in
    c land mask
  )

let is_set bits n = get bits n <> 0

let is_clear bits n = get bits n = 0

(*----------------------------------------------------------------------*)
(* Display functions. *)

let isprint c =
  let c = Char.code c in
  c >= 32 && c < 127

let hexdump_bitstring chan (data, off, len) =
  let count = ref 0 in
  let off = ref off in
  let len = ref len in
  let linelen = ref 0 in
  let linechars = String.make 16 ' ' in

  fprintf chan "00000000  ";

  while !len > 0 do
    let bits = min !len 8 in
    let byte = extract_char_unsigned data !off !len bits in
    off := !off + bits; len := !len - bits;

    let byte = byte lsl (8-bits) in
    fprintf chan "%02x " byte;

    incr count;
    linechars.[!linelen] <-
      (let c = Char.chr byte in
       if isprint c then c else '.');
    incr linelen;
    if !linelen = 8 then fprintf chan " ";
    if !linelen = 16 then (
      fprintf chan " |%s|\n%08x  " linechars !count;
      linelen := 0;
      for i = 0 to 15 do linechars.[i] <- ' ' done
    )
  done;

  if !linelen > 0 then (
    let skip = (16 - !linelen) * 3 + if !linelen < 8 then 1 else 0 in
    for i = 0 to skip-1 do fprintf chan " " done;
    fprintf chan " |%s|\n%!" linechars
  ) else
    fprintf chan "\n%!"
