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

type _ t =
  | Type : 'a -> 'a t (* module type *)
  | Function : 'a t * 'b t -> ('a -> 'b) t

let v x = Type x

let ( @-> ) f x = Function (f, x)

let rec pp : type a. a t Fmt.t =
 fun ppf -> function
  | Type _ -> Fmt.string ppf "_"
  | Function (a, b) -> Fmt.pf ppf "(%a -> %a)" pp a pp b

type job = JOB

let job = Type JOB

(* Default argv *)

type argv = ARGV

let argv = Type ARGV

(* Keys *)

type info = INFO

let info = Type INFO

let is_functor : type a. a t -> bool = function
  | Type _ -> false
  | Function _ -> true
