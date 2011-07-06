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

external wire_string: string -> int * int = "caml_wire_string_pages"
external unwire_string: string -> unit = "caml_unwire_string_pages"

let free_list = Queue.create ()

let alloc ~nr_pages =
  let buf = String.create ((nr_pages * 4096) + 1) in
  let off, nr = wire_string buf in
  assert (nr = nr_pages);
  let off = off * 8 in (* bitstrings offsets are in bits *)
  for i = 0 to nr_pages - 1 do
    let bs = buf, (off + (i*4096)), 4096 in
    Queue.add bs free_list;
  done

let rec get_free () =
  try
    Queue.pop free_list
  with Queue.Empty -> begin
    alloc 128;
    get_free ()
  end

let put_free bs =
  (* TODO: assert that the buf is a page aligned one we allocated above *)
  Queue.add bs free_list

