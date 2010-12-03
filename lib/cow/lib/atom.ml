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

(* Atom Syndication format output. Bare minimum for a reader to use, feel
   free to extend from the full spec at:
   http://www.atomenabled.org/developers/syndication/atom-format-spec.php
*)
type author = {
  name: string;
  uri: string option;
  email: string option;
} with xml

type date =
    int * int * int * int * int (* year, month, date, hour, minute *)
with xml

let xml_of_date (year,month,day,hour,min) =
  let str = Printf.sprintf "%.4d-%.2d-%.2dT%.2d:%.2d:00Z" year month day hour min in
  <:xml< $str:str$ >>

type meta = {
  id: string;
  title: string;
  subtitle: string option;
  author: author option;
  contributors: author list;
  rights: string option;
  updated: date;
} with xml

type content = Xml.t

let xml_of_content c = <:xml<
  <content type="xhtml" xml:lang="en" xml:base="http://diveintomark.org/">
    $c$
  </content>
>>

type entry = {
  entry: meta;
  summary: string option;
  content: content;
} with xml

type feed = {
  feed: meta;
  entries: entry list;
}

let xml_of_feed f = <:xml<
  <feed xmlns="http://www.w3.org/2005/Atom">
     $xml_of_meta f.feed$
     $list:List.map xml_of_entry f.entries$
  </feed>
>>

let compare (yr1,mn1,da1,_,_) (yr2,mn2,da2,_,_) =
  match yr1 - yr2 with
    | 0 ->
      (match mn1 - mn2 with
        | 0 -> da1 - da2
        | n -> n
      )
    | n -> n
