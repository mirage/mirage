(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.org>
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

type t = (('a Xml.frag as 'a) Xml.frag) list

let id x = x

let rec output_t output = function
  | (`Data _ as d) :: t ->
    Xml.output output d;
    output_t output t
  | (`El _ as e) :: t   ->
    Xml.output_tree id output e;
    Xml.output output (`Dtd None);
    output_t output t
  | [] -> ()

let to_string t =
  let buf = Buffer.create 1024 in
  let output = Xml.make_output (`Buffer buf) in
  Xml.output output (`Dtd None);
  output_t output t;
  Buffer.contents buf

type link = {
  text : string;
  href: string;
}

let html_of_link l : t =
  <:html<<a href=$str:l.href$>$str:l.text$</a>&>>

(* color tweaks for lists *)
let interleave classes l =
  let i = ref 0 in
  let n = Array.length classes in
  let get () =
    let res = classes.(!i mod n) in
    incr i;
    res in
  List.map (fun elt -> <:html< <div class=$str:get ()$>$elt$</div> >>) l
