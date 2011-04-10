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

let encoding : Xml.encoding option ref = ref None

let set_encoding e =
  encoding := Some e

let get_encoding () =
  !encoding

(* Antiquotation $...$ are converted to the strings '$i$', where i is the order
   in which the quotation appears in the program. So we deal with only one level
   of antiquotations here (ie. we do not support nested quotations). But that's
   not a big limitation as it is always possible to create intermediate values
   to handle the nesting. *)

(*** encoding ***)

let antiquotations = Hashtbl.create 64

let find_antiquotation i =
  Hashtbl.find antiquotations i

let add_antiquotation i aq =
  Hashtbl.add antiquotations i aq
  
let mem_antiquotation i = Hashtbl.mem antiquotations i

let is_alist str =
  try String.sub str 0 6 = "alist:"
  with _ -> false

let is_attrs str =
  try String.sub str 0 6 = "attrs:"
  with _ -> false

let antiquotation_encoding = Str.regexp "\\$[^$]+\\$" (* only one level of quotations *)

let count = ref 0
let encoding str =
  let c = Str.matched_string str in
  let c = String.sub c 1 (String.length c - 2) in
  let r0 = Printf.sprintf "$%i$" !count in
  let r1 = Printf.sprintf "'$%i$'" !count in
  let output =
    if is_alist c then
      Printf.sprintf "alist=%s" r1
    else if is_attrs c then
      Printf.sprintf "attrs=%s" r1
    else        
      r1 in
  incr count;
  add_antiquotation r0 c;
  add_antiquotation r1 c;
  output

let encode str =
  Str.global_substitute antiquotation_encoding encoding str

(*** decoding ***)

open Qast

let antiquotation_decoding = Str.regexp "'\\$[0-9]*\\$'"

let decode loc input str =
  let split = Str.full_split antiquotation_decoding str in
  let aux = function
    | Str.Text s  -> String s
    | Str.Delim s -> Ant (Location.add loc (Xml.pos input), find_antiquotation s) in
  t_of_list (List.map aux split)

let decode_quoted loc input str =
  if mem_antiquotation str && str.[0] = '$' then
    decode loc input (Printf.sprintf "'%s'" str)
  else
    decode loc input str

(*** XHTML parsing (using Xml) ***)
let input_tree loc input =
  let el (name, attrs) body =
    let (_,name) = name in
    let name = decode loc input name in
    let attrs = List.map (fun ((_,k),v) ->
      if k="alist" || k="attrs" then
        decode_quoted loc input v
      else
        Prop (decode loc input k, decode_quoted loc input v)) attrs in
    Tag (name, t_of_list attrs, t_of_list body) in
  let data str =
    decode loc input str in
  Xml.input_tree ~el ~data input
  
let parse loc ?entity ?enc str =
  (* It is illegal to write <:html<<b>foo</b>>> so we use a small trick and write
     <:html<<b>foo</b>&>> *)
  let str = if str.[String.length str - 1] = '&' then
    String.sub str 0 (String.length str - 1)
  else
    str in
  (* Xml.input needs a root tag *)
  let str = Printf.sprintf "<xxx>%s</xxx>" str in
  let str = encode str in
  try
    let input = Xml.make_input ~enc ?entity (`String (0,str)) in
    (* Xml.make_input builds a well-formed document, so discard the Dtd *)
    (match Xml.peek input with
      | `Dtd _ -> let _ = Xml.input input in ()
      | _      -> ());
    (* Remove the dummy root tag *)
    match input_tree loc input with
      | Tag (String "xxx", Nil, body) -> body
      | _ -> Location.raise loc (0,1) Parsing.Parse_error
  with Xml.Error (pos, e) ->
    Printf.eprintf "[XMLM:%d-%d] %s: %s\n"(fst pos) (snd pos) str (Xml.error_message e);
    Location.raise loc pos Parsing.Parse_error

