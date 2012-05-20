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

let free_list = Queue.create ()

let page_size = 4096

let create sz = Array1.create char c_layout sz 

let alloc ~nr_pages =
  let rec inner =
    function
    |0 -> ()
    |n ->
       Queue.add (create page_size) free_list;
       inner (n-1)
  in
  inner nr_pages

let get () =
  let rec inner () =
    try
      let page = Queue.pop free_list in
      (* Add finaliser to put it back in the pool *)
(*
      let fin p =
        Printf.printf "page finalise\n%!";
        Queue.add p free_list
      in 
      Gc.finalise fin page;
*)
      page
    with Queue.Empty -> begin
      alloc ~nr_pages:128;
      inner ()
    end in
  inner ()

let rec get_n = function
  | 0 -> []
  | n -> get () :: (get_n (n - 1))

let sub t off len = Array1.sub t off len

let length t = Array1.dim t

let round_to_page_size n = ((n+4095) lsr 12) lsl 12
