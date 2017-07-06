(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

(** Utility module. *)

(** {2 Misc} *)

open Rresult

val err_cmdliner: ?usage:bool -> ('a, string) result -> 'a Cmdliner.Term.ret

module type Monoid = sig
  type t
  val empty: t
  val union: t -> t -> t
end

(** Generation of fresh names *)
module Name: sig
  val ocamlify: string -> string
  val create: string -> prefix:string -> string
end

module Codegen: sig
  val generated_header: unit -> string
  val append: Format.formatter -> ('a, Format.formatter, unit) format -> 'a
  val newline: Format.formatter -> unit
  val set_main_ml: string -> unit
  val append_main: ('a, Format.formatter, unit) format -> 'a
  val newline_main: unit -> unit
end

(** Universal map *)
module Univ: sig
  type 'a key
  val new_key: string -> 'a key
  type t
  val empty: t
  val add: 'a key -> 'a -> t -> t
  val mem: 'a key -> t -> bool
  val find: 'a key -> t -> 'a option
  val merge: default:t -> t -> t
  val dump: t Fmt.t
end
