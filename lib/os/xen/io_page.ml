(*
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


type t = (char, Bigarray.int8_unsigned_elt, Bigarray.c_layout) Bigarray.Array1.t

external alloc_pages: int -> t array = "caml_alloc_pages"

(* pages_per_block -> queue of free blocks *)
let free_lists = Hashtbl.create 10

let get_free_list pages_per_block : t Queue.t =
  if not(Hashtbl.mem free_lists pages_per_block)
  then Hashtbl.add free_lists pages_per_block (Queue.create ());
  Hashtbl.find free_lists pages_per_block

let alloc ~pages_per_block ~n_blocks =
  let q = get_free_list pages_per_block in
  for i = 0 to n_blocks - 1 do
    Array.iter (fun x -> Queue.add x q) (alloc_pages pages_per_block);
  done

let get ?(pages_per_block=1) () =
  let q = get_free_list pages_per_block in
  let rec inner () =
    try
      let block = Queue.pop q in
      let fin p =
        Printf.printf "block finalise\n%!";
        Queue.add p q
      in 
      Gc.finalise fin block;
      block
    with Queue.Empty -> begin
      alloc ~pages_per_block ~n_blocks:128;
      inner ()
    end in
  inner ()

let rec get_n ?(pages_per_block=1) n = match n with
  | 0 -> []
  | n -> get () :: (get_n ~pages_per_block (n - 1))

let sub t off len = Bigarray.Array1.sub t off len

let length t = Bigarray.Array1.dim t
