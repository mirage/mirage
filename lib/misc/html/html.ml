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

type t = (('a Xmlm.frag as 'a) Xmlm.frag) list

let id x = x

let rec output_t output = function
  | (`Data _ as d) :: t ->
    Xmlm.output output d;
    output_t output t
  | (`El _ as e) :: t   ->
    Xmlm.output_tree id output e;
    Xmlm.output output (`Dtd None);
    output_t output t
  | [] -> ()

let to_string t =
  let buf = Buffer.create 1024 in
  let output = Xmlm.make_output (`Buffer buf) in
  Xmlm.output output (`Dtd None);
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

module Code = struct

  let keywords1 = [
    "|";
    "do";
    "done";
    "downto";
    "else";
    "for";
    "if";
    "lazy";
    "match";
    "new";
    "or";
    "then";
    "to";
    "try";
    "when";
    "while";
  ]

  let keywords2 = [
    "assert";
    "include";
  ]

  let keywords3 = [
    "open";
  ]
    
  let keywords4 = [
    "and";
    "as";
    "class";
    "constraint";
    "exception";
    "external";
    "fun";
    "function";
    "functor";
    "in";
    "inherit";
    "initializer";
    "let";
    "method";
    "module";
    "mutable";
    "of";
    "private";
    "rec";
    "type";
    "val";
    "virtual";
  ]

  let keywords5 = [
    "raise";
  ]

  let keywords6 = [
    "asr";
    "land";
    "lor";
    "lsl";
    "lsr";
    "lxor";
    "mod";
  ]

  let keywords7 = [
    "begin";
    "end";
    "object";
    "sig";
    "struct";
  ]

  let keywords8 = [
    "false";
    "true";
  ]

  type keyword1 = string with html
  type keyword2 = string with html
  type keyword3 = string with html
  type keyword4 = string with html
  type keyword5 = string with html
  type keyword6 = string with html
  type keyword7 = string with html
  type keyword8 = string with html

  let keywords = [| keywords1; keywords2; keywords3; keywords4; keywords5; keywords6; keywords7 |]
    
  let is_keyword str =
    Str.string_match (Str.regexp (String.concat "\\|" (List.concat (Array.to_list keywords)))) str 0

  exception Found of int

  let find_class str =
    try
      for i = 0 to 7 do
        if List.mem str keywords.(i) then
          raise (Found i)
      done;
      raise Not_found
    with Found i ->
      i

  let html_of_keywords = [|
    html_of_keyword1;
    html_of_keyword2;
    html_of_keyword3;
    html_of_keyword4;
    html_of_keyword5;
    html_of_keyword6;
    html_of_keyword7;
    html_of_keyword8;
  |]
 
  let ocaml str =
    let rec aux accu = function
      | []                 -> List.rev accu
      | Str.Delim str :: t -> aux (`Data str :: accu) t
      | Str.Text str  :: t -> 
        if is_keyword str then
          aux ((html_of_keywords.(find_class str) str) @ accu) t
        else
          aux (`Data str :: accu) t in
    aux [] (Str.full_split (Str.regexp "[ \n\t]+") str)
end
