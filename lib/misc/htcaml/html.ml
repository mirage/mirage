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

type t =
  | String of string
  | Tag of string * t * t
  | Prop of t * t
  | Seq of t * t
  | Nil

let rec t_of_list = function
  | [] -> Nil
  | [e] -> e
  | e::es -> Seq (e, t_of_list es)

let rec list_of_t x acc =
  match x with
  | Nil -> acc
  | Seq (e1, e2) -> list_of_t e1 (list_of_t e2 acc)
  | e -> e :: acc

open Printf
open Format

let rec next_string = function
  | String s        -> Some s
  | Seq(String s,_) -> Some s
  | Seq(t,_)        -> next_string t
  | _               -> None

(* XXX: make it complete *)
let matching = Str.regexp "é\\|ë\\|è\\|à"
let encoding str =
  match Str.matched_string str with
    | "é" -> "&eacute;"
    | "ë" -> "&euml;"
    | "è" -> "&egrave;"
    | "à" -> "&agrave;"
    | _   -> assert false
let encode str =
   Str.global_substitute matching encoding str

let rec t ppf = function
  | String s         -> fprintf ppf "%s" (encode s)
  | Tag (s, Nil, Nil)-> fprintf ppf "<%s/>" s
  | Tag (s, Nil, t1) -> fprintf ppf "@[<hov 1><%s>%a</%s>@]" s t t1 s
  | Tag (s, l, Nil)  -> fprintf ppf "@[<hov 1><%s %a/>@]" s t l
  | Tag (s, l, t1)   -> fprintf ppf "@[<hov 1><%s %a>%a</%s>@]" s t l t t1 s
  | Prop (k,v)       -> fprintf ppf "%a=%a" t k t v
  | Seq (t1, Nil)    -> t ppf t1
  | Seq (t1, t2)     ->
    let str = next_string t2 in
    if str = Some "." || str = Some "," || str = Some ";" then
      fprintf ppf "%a%a" t t1 t t2
    else
      fprintf ppf "%a@ %a" t t1 t t2
  | Nil              -> ()

let to_buf buf t' =
  let ac = Buffer.add_char buf  in
  let ax = Buffer.add_string buf in
  let tag x = ac '<'; ax x; ac '>' in
  let ctag x = ax "</"; ax x; ac '>' in
  let rec t = function
  | String s -> ax (encode s)
  | Tag (s, Nil, Nil) -> ac '<'; ax s; ax "/>"
  | Tag (s, Nil, t1) -> tag s; t t1; ctag s
  | Tag (s, l, Nil)  -> ac '<'; ax s; ac ' '; t l; ax "/>"
  | Tag (s, l, t1)   -> ac '<'; ax s; ac ' '; t l; ac '>'; t t1; ax "</"; ax s; ac '>'
  | Prop (k,v)       -> t k; ac '='; t v
  | Seq (t1, Nil)    -> t t1
  | Seq (t1, t2)     ->
    let str = next_string t2 in
    if str = Some "." || str = Some "," || str = Some ";" then
      (t t1; t t2)
    else
      (t t1; ac ' '; t t2)
  | Nil              -> () in
  t t'


(* XXX: write a sanitizer *)
let sanitaze t = t

(* XXX: This stringifier does not preserve whitespace, e.g. for <pre> tags 
let to_string t' =
  t str_formatter t';
  sanitaze (flush_str_formatter ())
*)

let to_string t =
  let buf = Buffer.create 1024 in
  to_buf buf t;
  Buffer.contents buf

let rec t_of_list = function
  | [] -> Nil
  | [e] -> e
  | e::es -> Seq (e, t_of_list es)

type link = {
  text : string;
  href: string;
}

let html_of_link l =
  Tag ("a",
       Prop(String "href", String ("\"" ^ l.href ^ "\"")),
       String l.text)
