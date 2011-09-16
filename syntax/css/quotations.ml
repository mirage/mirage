(*
 * Copyright (c) 2010-2011 Thomas Gazagnaire <thomas@ocamlpro.com>
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

open Camlp4.PreCast

module Q = Syntax.Quotation
module AQ = Syntax.AntiquotSyntax

let destruct_aq s =
  try
    let pos = String.index s ':' in
    let space = String.index s ' ' in
    if space < pos then raise Not_found;
    let len = String.length s in
    let name = String.sub s 0 pos
    and code = String.sub s (pos + 1) (len - pos - 1) in
    name, code
  with Not_found ->
    "", s

let aq_expander =
object
  inherit Ast.map as super
  method expr =
    function
      | Ast.ExAnt (_loc, s) ->
          let n, c = destruct_aq s in
          let e = AQ.parse_expr _loc c in
          begin match n with
            | "expr" -> <:expr< Css.Exprs [List.flatten (List.map Css.expr $e$)] >> 
            | "prop" -> <:expr< Css.Props $e$ >>
            | "" -> e
            | t ->
              Printf.eprintf "[ERROR] \"%s\" is not a valid tag. Valid tags are [expr|prop]\n" t;
              Loc.raise _loc Parsing.Parse_error
          end
      | e -> super#expr e
end

let parse_quot_string fn _loc s =
  Location.set _loc;
  let res = fn QLexer.token (Lexing.from_string s) in
  res

let expand_expr fn _loc _ s =
  let ast = parse_quot_string fn _loc s in
  let meta_ast = Qast.meta_t _loc ast in
  if !Options.needsopen then
    <:expr< let open Cow in $aq_expander#expr meta_ast$ >>
  else
    aq_expander#expr meta_ast

let expand_str_item fn _loc _ s =
  let exp_ast = expand_expr fn _loc None s in
  <:str_item< $exp:exp_ast$ >>

;;

Q.add "css" Q.DynAst.expr_tag (expand_expr Parser.main);
Q.add "css" Q.DynAst.str_item_tag (expand_str_item Parser.main)
