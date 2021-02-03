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

open Rresult
open Astring

let err_cmdliner ?(usage = false) = function
  | Ok x -> `Ok x
  | Error s -> `Error (usage, s)

module type Monoid = sig
  type t

  val empty : t

  val union : t -> t -> t
end

(* {Misc informations} *)

module Name = struct
  let ocamlify s =
    let b = Buffer.create (String.length s) in
    String.iter
      (function
        | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_') as c ->
            Buffer.add_char b c
        | '-' | '.' -> Buffer.add_char b '_'
        | _ -> ())
      s;
    let s' = Buffer.contents b in
    if String.length s' = 0 || ('0' <= s'.[0] && s'.[0] <= '9') then
      raise (Invalid_argument s);
    s'
end

module Eq = struct
  type (_,_) eq = Eq : ('a,'a) eq | NotEq : ('a,'b) eq
  let andeq :
    type a b c d. (a,b) eq -> (c,d) eq -> (a*c,b*d) eq =
    fun a b -> match a, b with
    | Eq, Eq -> Eq
    | _ -> NotEq
  let andb b q = if b then q else NotEq
  let to_bool : type a b. (a,b) eq -> bool = function Eq -> true | NotEq -> false

  module Id = struct type _ t = .. end
  module type ID = sig
    type t
    type _  Id.t += Tid : t Id.t
    val id : int
  end

  type 'a t = (module ID with type t = 'a)

  let id = let r = ref 0 in fun () -> incr r ; !r
  let id () (type s) =
    let module M = struct
      type t = s
      type _ Id.t += Tid : t Id.t
      let id = id ()
    end
    in
    (module M : ID with type t = s)

  let equal : type r s. r t -> s t -> (r, s) eq =
    fun r s ->
    let module R = (val r : ID with type t = r) in
    let module S = (val s : ID with type t = s) in
    match R.Tid with
    | S.Tid -> Eq
    | _ -> NotEq
  let equal' a b = to_bool @@ equal a b
  let pp (type a) ppf ((module M) : a t) = Fmt.int ppf M.id
  let hash (type a) ((module M) : a t) = M.id
end
