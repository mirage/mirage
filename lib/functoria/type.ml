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

type _ typ =
  | Type : 'a -> 'a typ (* module type *)
  | Function : 'a t * 'b t -> ('a -> 'b) typ

and 'a t = { typ : 'a typ; packages : Package.t list }

let v ?(packages = []) x = { packages; typ = Type x }
let ( @-> ) f x = { packages = []; typ = Function (f, x) }

let packages t =
  let rec aux : type a. _ -> a t -> _ =
   fun acc t ->
    match t.typ with
    | Type _ -> Package.Set.(union acc (of_list t.packages))
    | Function (a, b) -> aux (aux acc a) b
  in
  Package.Set.to_list (aux Package.Set.empty t)

let rec pp : type a. a t Fmt.t =
 fun ppf t ->
  match t.typ with
  | Type _ -> Fmt.string ppf "_"
  | Function (a, b) -> Fmt.pf ppf "(%a -> %a)" pp a pp b

type job = JOB

let job = v JOB

(* Default argv *)

type argv = ARGV

let argv = v ARGV

(* Keys *)

type info = INFO

let info = v INFO

let is_functor : type a. a t -> bool = function
  | { typ = Type _; _ } -> false
  | { typ = Function _; _ } -> true
