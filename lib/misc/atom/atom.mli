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
 *
 *)

type field = [ `Empty | `Text of string ]
type author = { name : string; uri : string option; email : string option; }
type date = int * int * int * int * int
type meta = {
  id : string;
  title : field;
  subtitle : field;
  author : author option;
  contributors : author list;
  rights : string option;
  updated: date;
}
type entry = { entry : meta; summary : field; content : field; }
type feed = { feed : meta; entries : entry list; }
val output_entry : entry -> Xmlm.output -> unit
val output_feed : feed -> Xmlm.output -> unit
val string_of_feed : feed -> string
val sort : date -> date -> int
