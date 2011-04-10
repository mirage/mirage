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

open Camlp4.PreCast (* for Ast refs in generated code *)

(* The raw CSS fragments (after the parsing / before the lifting) *)
type t =
  | String of string
  | Decl of t * t
  | Rule of t * t
  | Fun of t * t
  | Comma of t * t
  | ESeq of t * t (* sequence of elements *)
  | RSeq of t * t (* sequence of rules/declarations *)
  | Nil
  | Ant of Loc.t * string

let get_expr _loc m =
  match m with
    | <:expr< Css.Exprs [ $e$ ] >> -> <:expr< $e$ >>
    | m -> <:expr< Css.expr $m$ >>

let get_exprs _loc m =
  match m with
    | <:expr< Css.Exprs $e$ >> -> <:expr< $e$ >>
    | m -> <:expr< Css.exprs $m$ >>

let get_props _loc m =
  match m with
    | <:expr< Css.Props $e$ >> -> <:expr< $e$ >>
    | m -> <:expr< Css.props $m$ >>

let get_string _loc m =
  match m with
    | <:expr< Css.Exprs [ [Css.Str $e$] ] >> -> <:expr< $e$ >>
    | m -> <:expr< Css.string $m$ >>

let rec meta_t _loc = function
  | String s ->
    <:expr< Css.Exprs [[Css.Str $`str:s$]] >>

  | Decl (a,b) ->
    let elts  = get_exprs _loc (meta_t _loc a) in
    let props = get_props _loc (meta_t _loc b) in
    <:expr< Css.Props [ Css.Decl ($elts$, $props$) ] >>

  | Rule (a,b) ->
    let name  = get_string _loc (meta_t _loc a) in
    let props = get_exprs _loc (meta_t _loc b) in
    <:expr< Css.Props [ Css.Prop ($name$, $props$) ] >>

  | Fun (a,b) ->
    let name = get_string _loc (meta_t _loc a) in
    let args = get_exprs _loc (meta_t _loc b) in
    <:expr< Css.Exprs [[Css.Fun ($name$, $args$) ]] >>

  | Comma (a,b) ->
    let e1 = get_exprs _loc (meta_t _loc a) in
    let e2 = get_exprs _loc (meta_t _loc b) in
    <:expr< Css.Exprs ($e1$ @ $e2$) >>

  | ESeq (a,b) ->
    let e1 = get_expr _loc (meta_t _loc a) in
    let e2 = get_expr _loc (meta_t _loc b) in
    <:expr< Css.Exprs [ ($e1$ @ $e2$) ] >>

  | RSeq (a,b) ->
    let e1 = get_props _loc (meta_t _loc a) in
    let e2 = get_props _loc (meta_t _loc b) in
    <:expr< Css.Props ($e1$ @ $e2$) >>

  | Nil ->
    <:expr< Css.Exprs [[]] >>

  | Ant (l, str) ->
    Ast.ExAnt (l, str)

let meta_t _loc t =
  let m = meta_t _loc t in
  match m with
    | <:expr< Css.Exprs $_$ >> -> m
    | t -> <:expr< Css.unroll $m$ >>

