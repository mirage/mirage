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

(** Dune files. *)

type stanza

val stanza : string -> stanza
val stanzaf : ('a, Format.formatter, unit, stanza) format4 -> 'a

type t

val v : stanza list -> t
val pp : t Fmt.t
val to_string : t -> string
val compact_list : ?indent:int -> string -> string list Fmt.t

val config : config_file:Fpath.t -> packages:Package.t list -> stanza list
(** the minimal [dune] file to compile [config.ml]. *)

val lib :
  config_file:Fpath.t -> packages:Package.t list -> string -> stanza list
(** the minimal [dune] file to compile the application functor as a library. *)

val promote_files : gen_dir:Fpath.t -> main:Fpath.t -> unit -> stanza list

val project : t
(** the minimal [dune-project] to compile [config.ml]. *)

val workspace : t
(** the minimal [dune-workspace] to compile [config.ml]. *)
