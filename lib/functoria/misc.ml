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
  module Opam = struct
    type t = string

    let to_string = Fun.id
  end

  let opamify s =
    let b = Buffer.create (String.length s) in
    String.iter
      (function
        | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' | '-') as c ->
            Buffer.add_char b c
        | '.' -> Buffer.add_char b '_'
        | _ -> ())
      s;
    let s' = Buffer.contents b in
    if String.length s' = 0 then raise (Invalid_argument s);
    s'

  let ocamlify s =
    let b = Buffer.create (String.length s) in
    String.iter
      (function
        | ('a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_') as c ->
            Buffer.add_char b c
        | '-' | '.' | ' ' -> Buffer.add_char b '_'
        | _ -> ())
      s;
    let s' = Buffer.contents b in
    if String.length s' = 0 || ('0' <= s'.[0] && s'.[0] <= '9') then
      raise (Invalid_argument s);
    s'
end
