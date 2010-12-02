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

open Camlp4.PreCast

let expr_list_of_list _loc exprs =
	match List.rev exprs with
	| []   -> <:expr< [] >>
	| h::t ->
    List.fold_left (fun accu x -> <:expr< [ $x$ :: $accu$ ] >>) <:expr< [ $h$ ] >> t 

type t =
  | String of string
  | Tag of t * t * t
  | Prop of t * t
  | Seq of t * t
  | Nil
  | Ant of Loc.t * string

let rec t_of_list = function
  | [] -> Nil
  | [e] -> e
  | e::es -> Seq (e, t_of_list es)

let rec list_of_t x acc =
  match x with
  | Nil -> acc
  | Seq (e1, e2) -> list_of_t e1 (list_of_t e2 acc)
  | e -> e :: acc

let get_string _loc m =
  match m with
  | <:expr< [ `Data $str:x$ ] >> -> <:expr< $str:x$ >>
  | _ ->
    <:expr< match $m$ with [ [`Data str] -> str | _ -> raise Parsing.Parse_error ] >>

(* Convert a value of type t to Html.t = Xml.frag *)
let rec meta_t _loc = function
  | String s    ->
    <:expr< [`Data $`str:s$] >>

  | Tag (t,l,s) ->
    let tag = get_string _loc (meta_t _loc t) in
    let attrs = meta_t _loc l in
    let body = meta_t _loc s in
    <:expr< [`El (("",$tag$), $attrs$) $body$] >>

  | Prop (k,v)  ->
    let mk = get_string _loc (meta_t _loc k) in
    let mv = get_string _loc (meta_t _loc v) in
    <:expr< [(("",$mk$), $mv$)] >>

  | Seq (a,b)   ->
    let la = list_of_t a [] in
    let lb = list_of_t b [] in
    let l = List.map (meta_t _loc) (la @ lb) in
    <:expr< List.flatten $expr_list_of_list _loc l$ >> 

  | Nil         ->
    <:expr< [] >>

  | Ant (l, str) ->
    Ast.ExAnt (l, str)
