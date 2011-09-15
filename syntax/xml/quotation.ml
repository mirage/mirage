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
    let len = String.length s in
    let name = String.sub s 0 pos
    and code = String.sub s (pos + 1) (len - pos - 1) in
    name, code
  with Not_found ->
    "", s

let parse_quot_string entity _loc s =
  let ast = Parser.parse ?enc:(Parser.get_encoding ()) ?entity _loc s in
  let meta_ast = Qast.meta_t _loc ast in
  meta_ast

let aq_expander =
object
  inherit Camlp4.PreCast.Ast.map as super
  method expr =
    function
      | Camlp4.PreCast.Ast.ExAnt (_loc, s) ->
        let n, c = destruct_aq s in
        let e = AQ.parse_expr _loc c in
        begin match n with
          | "opt"   -> <:expr< match $e$ with [ Some xml -> xml | None -> [] ] >>
          | "int"   -> <:expr< [`Data (string_of_int $e$)] >> 
          | "flo"   -> <:expr< [`Data (string_of_float $e$)] >>
          | "str"   -> <:expr< [`Data $e$] >>
          | "alist" -> <:expr< List.map (fun (k,v) -> (("",k),v)) $e$ >> 
          | "list"  -> <:expr< List.flatten $e$ >>
          | "attrs" ->

            <:expr<
              let key_value str =
                try
                  let pos = String.index str '=' in
                  let k = String.sub str 0 pos in
                  let v = String.sub str (pos+1) (String.length str - pos - 1) in
                  let v =
                    if   (v.[0] = '"' && v.[String.length v - 1] = '"')
                      || (v.[0] = '\'' && v.[String.length v - 1] = '\'') then
                      String.sub v 1 (String.length v - 2)
                    else
                      raise Parsing.Parse_error in
                  (("",k),v)
                with _ ->
                  raise Parsing.Parse_error in
              
              let rec split ?(accu=[]) c s =
                try
                  let i = String.index s c in
                  let prefix = String.sub s 0 i in
                  let suffix =
                    if i = String.length s - 1 then
                      ""
                    else
                      String.sub s (i+1) (String.length s - i - 1) in
                  split ~accu:[prefix :: accu] c suffix
                with _ ->
                  List.rev [s :: accu] in
              
              match $e$ with [
                [`Data str] -> List.map (fun x -> key_value x) (split ' ' str) 
              | _ -> raise Parsing.Parse_error ] >>

                | "" -> <:expr< $e$ >>
                | x  ->
                  Printf.eprintf "[ERROR] %s is not a valid tag.\nAllowed tags are [opt|int|flo|str|list|alist|attrs] or the empty one." x;
                  Loc.raise _loc Parsing.Parse_error
        end
      | e -> super#expr e
end

let expand_expr entity =
  fun _loc _ s ->
    let meta_ast = parse_quot_string entity _loc s in
    if !Options.needsopen then
      <:expr< let open Cow in ($aq_expander#expr meta_ast$ : Xml.t) >>
    else
      <:expr< ($aq_expander#expr meta_ast$ : Xml.t) >>

let expand_str_item entity _loc _ s =
  let exp_ast = expand_expr entity _loc None s in
  <:str_item< $exp:exp_ast$ >>

let () =
  Q.add "xml" Q.DynAst.expr_tag (expand_expr None);
  Q.add "xml" Q.DynAst.str_item_tag (expand_str_item None)
