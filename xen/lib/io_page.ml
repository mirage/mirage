(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (C) 2012 Citrix Systems Inc
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


type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external alloc_pages: int -> t option = "caml_alloc_pages"

let get ?(pages_per_block=1) () =
	match alloc_pages pages_per_block with
	| Some block -> block
	| None ->
		Gc.compact ();
		begin match alloc_pages pages_per_block with
		| Some block -> block
		| None ->
			Printf.printf "out of memory\n%!";
			exit(1)
		end

let rec get_n ?(pages_per_block=1) n = match n with
  | 0 -> []
  | n -> get () :: (get_n ~pages_per_block (n - 1))

let rec pow2 = function
  | 0 -> 1
  | n -> 2 * (pow2 (n - 1))

let get_order order = get ~pages_per_block:(pow2 order) ()

let to_cstruct t = Cstruct.of_bigarray t

let length t = Bigarray.Array1.dim t

let page_size = 4096

let to_pages t =
  assert(length t mod page_size = 0);
  let rec loop off acc =
    if off < (length t)
    then loop (off + page_size) (Bigarray.Array1.sub t off page_size :: acc)
    else acc in
  List.rev (loop 0 [])

let string_blit src t =
  for i = 0 to String.length src - 1 do
    t.{i} <- src.[i]
  done

let to_string t =
  let result = String.create (length t) in
  for i = 0 to length t - 1 do
    result.[i] <- t.{i}
  done;
  result

let blit src dest = Bigarray.Array1.blit src dest
