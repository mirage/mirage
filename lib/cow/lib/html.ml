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

type t = Xml.t

let to_string = Xml.to_string

let of_string ?templates ?enc str =
  Xml.of_string ~entity:Xhtml.entity ?templates ?enc str

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

let html_of_string s = <:html<$str:s$>>
let html_of_int i = <:html<$int:i$>>
let html_of_float f = <:html<$flo:f$>>

type table = t array array

let html_of_table ?(headings=false) t =
  let tr x = <:html<<tr>$list:x$</tr>&>> in
  let th x = <:html<<th>$x$</th>&>> in
  let td x = <:html<<td>$x$</td>&>> in
  let hd =
    if Array.length t > 0 && headings then
      let l = Array.to_list t.(0) in
      Some (tr (List.map th l))
    else
      None in
  let tl =
    if Array.length t > 1 && headings then
      List.map Array.to_list (List.tl (Array.to_list t))
    else
      List.map Array.to_list (Array.to_list t) in
  let tl = List.map (fun l -> tr (List.map td l)) tl in
  <:html<<table>$opt:hd$ $list:tl$</table>&>>
    
let nil : t = []
