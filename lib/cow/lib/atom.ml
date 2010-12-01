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
type field = [
  | `XML of string 
  | `Text of string
  | `Empty
]

type author = {
  name: string;
  uri: string option;
  email: string option;
}

type date = int * int * int * int * int (* year, month, date, hour, minute *)

type meta = {
  id: string;
  title: field;
  subtitle: field;
  author: author option;
  contributors: author list;
  rights: string option;
  updated: date;
}
   
type entry = {
  entry: meta;
  summary: field;
  content: field;
}

type feed = {
  feed: meta;
  entries: entry list;
}

let tag ?(attrs=[]) n = ("", n), attrs

let output_tag t fn o =
  Xml.output o (`El_start t);
  fn o;
  Xml.output o `El_end

let maybe fn s o = 
  match s with 
  | None -> () 
  | Some x -> fn x o

let output_string t s = 
  output_tag t (fun o -> Xml.output o (`Data s))

let output_list t l o =
   match l with 
   | [] -> ()
   | _ ->
     output_tag t (fun o -> List.iter (fun x -> x o) l) o

let output_author t a =
  output_list t [
     output_string (tag "name") a.name;
     maybe (output_string (tag "email")) a.email;
     maybe (output_string (tag "uri")) a.uri
  ]

let output_field t (f:field) =
  output_tag t (fun o ->
    match f with
    | `Text s ->
        Xml.output o (`Data s)
    | `XML h ->
        Xml.output o (`Raw h)
    | `Empty -> ()
  )

let updated (year,month,day,hour,min) =
  Printf.sprintf "%.4d-%.2d-%.2dT%.2d:%.2d:00Z" year month day hour min

let output_meta m o =
  List.iter (fun x -> x o) [
    output_string (tag "id") m.id;
    output_field (tag "title") m.title;
    output_field (tag "subtitle") m.subtitle;
    output_string (tag "updated") (updated m.updated);
    maybe (output_author (tag "author")) m.author;
    maybe (output_string (tag "rights")) m.rights;
  ];
  List.iter (fun c -> output_author (tag "contributor") c o) m.contributors

let output_entry e =
  output_tag (tag "entry")
   (fun o ->  
     output_meta e.entry o;
     output_field (tag "summary") e.summary o;
     output_field (tag ~attrs:[("","type"),"xhtml";("","xml:lang"),"en"] "content") e.content o;
   ) 

let output_feed f =
  output_tag (tag ~attrs:[("","xmlns"),"http://www.w3.org/2005/Atom"] "feed")
    (fun o ->
      output_meta f.feed o;
      List.iter (fun e -> output_entry e o) f.entries;
    )

let string_of_feed f =
  let buf = Buffer.create 1024 in
  let o = Xml.make_output ~nl:false ~indent:None (`Buffer buf) in
  Xml.output o (`Dtd None);
  output_feed f o;
  Buffer.contents buf

(* polymorphic compare should do the right thing with a tuple of dates *)
let sort a b = compare a b
