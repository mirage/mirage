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

(* TCP sequence numbers must work with overflow, so this puts them in a
   separate type to make sure they dont get mixed up *)

type t = int32

(* a < b *)
let lt a b = (Int32.sub a b) < 0l

(* a <= b *)
let leq a b = (Int32.sub a b) <= 0l

(* a > b *)
let gt a b = (Int32.sub a b) > 0l

(* a >= b *)
let geq a b = (Int32.sub a b) >= 0l

(* b <= a <= c *)
let between a b c = (geq a b) && (leq a c)

(* a + b *)
let add a b = Int32.add a b

(* a++ *)
let incr a = Int32.add a 1l

let compare a b = Int32.compare a b 
let of_int32 t = t
let of_int t = Int32.of_int t
let to_int32 t = t
let to_string t = Printf.sprintf "%lu" t
