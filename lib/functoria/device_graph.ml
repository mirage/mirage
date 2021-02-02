(*
 * Copyright (c) 2013-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013-2020 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2015-2020 Gabriel Radanne <drupyog@zoho.com>
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

(* {1 Graph engine} *)

(* This module is not optimized for speed, it's optimized for correctness
   and readability. If you need to make it faster:
     - Good luck.
     - Please update the invariant section.
*)

open Astring


type t = D : {
  dev : ('a, _) Device.t ;
  args : t list ;
  deps : t list ;
  id : int ;
} -> t
type dtree = t

(* let dtree t =
 *   let r = ref 0 in
 *   let mk_app ~f:_ ~args:_ = raise Not_reduced
 *   and mk_switch ~cond:_ _ = raise Not_reduced
 *   and mk_dev = { f = fun ~args ~deps dev ->
 *       incr r;
 *       D { dev; args; deps; id = !r}
 *     }
 *   in
 *   try Some (map ~mk_switch ~mk_app ~mk_dev t)
 *   with Not_reduced -> None *)

module IdTbl = Hashtbl.Make(struct
    type t = dtree
    let hash (D t) = t.id
    let equal (D t1) (D t2) = Int.equal t1.id t2.id
  end)

(* We iter in *reversed* topological order. *)
let fold_dtree f t z =
  let tbl = IdTbl.create 50 in
  let state = ref z in
  let rec aux v =
    if IdTbl.mem tbl v then ()
    else
      let D { args; deps; _} = v in
      IdTbl.add tbl v ();
      List.iter aux deps;
      List.iter aux args;
      state := f v !state
  in
  aux t;
  !state

let nice_name d =
  Device.module_name d
  |> String.cuts ~sep:"."
  |> String.concat ~sep:"_"
  |> String.Ascii.lowercase
  |> Misc.Name.ocamlify

let impl_name (D { dev; args = _; deps = _ ; id }) =
  match Type.is_functor (Device.module_type dev) with
  | false -> Device.module_name dev
  | true ->
    let prefix = String.Ascii.capitalize (nice_name dev) in
    Fmt.strf "%s__%d" prefix id

let var_name (D { dev; args = _; deps = _ ; id}) =
  let prefix = nice_name dev in
  Fmt.strf "%s__%i" prefix id
