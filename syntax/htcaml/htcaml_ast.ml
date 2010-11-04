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

type t =
  | String of string
  | Tag of string * t * t
  | Prop of t * t
  | Seq of t * t
  | Nil

  | Ant of Loc.t * string

let rec meta_t _loc = function
  | String s    -> <:expr< Htcaml.Html.String $`str:s$ >>
  | Tag (t,l,s) -> <:expr< Htcaml.Html.Tag ($`str:t$, $meta_t _loc l$, $meta_t _loc s$) >>
  | Prop (k,v)  -> <:expr< Htcaml.Html.Prop ($meta_t _loc k$, $meta_t _loc v$) >>
  | Seq (a,b)   -> <:expr< Htcaml.Html.Seq ($meta_t _loc a$, $meta_t _loc b$) >> 
  | Nil         -> <:expr< Htcaml.Html.Nil >>

  | Ant (l, str) -> Ast.ExAnt (l, str)

let rec t_of_list = function
  | [] -> Nil
  | [e] -> e
  | e::es -> Seq (e, t_of_list es)

let rec list_of_t x acc =
  match x with
  | Nil -> acc
  | Seq (e1, e2) -> list_of_t e1 (list_of_t e2 acc)
  | e -> e :: acc
