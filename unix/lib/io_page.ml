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

open Bigarray

type t = (char, int8_unsigned_elt, c_layout) Array1.t

let page_size = 1 lsl 12

let length t = Array1.dim t

let get n = Array1.create char c_layout (n * page_size)

let get_order order = get (1 lsl order)

let to_pages t =
  assert(length t mod page_size = 0);
  let rec loop off acc =
    if off < (length t)
    then loop (off + page_size) (Bigarray.Array1.sub t off page_size :: acc)
    else acc in
  List.rev (loop 0 [])

let pages n = to_pages (get n)

let pages_order order = to_pages (get_order order)


let round_to_page_size n = ((n + page_size - 1) lsr 12) lsl 12

let to_cstruct t = Cstruct.of_bigarray t

let to_string t =
  let result = String.create (length t) in
  for i = 0 to length t - 1 do
    result.[i] <- t.{i}
  done;
  result

let blit src dest = Bigarray.Array1.blit src dest

let string_blit src srcoff dst dstoff len =
  for i = srcoff to srcoff + len - 1 do
    dst.{i+dstoff} <- src.[i]
  done



