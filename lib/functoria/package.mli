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

(** Representation of opam packages. *)

type t
(** The type for opam packages. *)

val v :
  ?build:bool ->
  ?sublibs:string list ->
  ?libs:string list ->
  ?min:string ->
  ?max:string ->
  ?pin:string ->
  string ->
  t
(** [v ~build ~sublibs ~libs ~min ~max ~pin opam] is a [package]. [Build]
    indicates a build-time dependency only, defaults to [false]. The library
    name is by default the same as [opam], you can specify [~sublibs] to add
    additional sublibraries (e.g. [~sublibs:\["mirage"\] "foo"] will result in
    the library names [\["foo"; "foo.mirage"\]]. In case the library name is
    disjoint (or empty), use [~libs]. Specifying both [~libs] and [~sublibs]
    leads to an invalid argument. Version constraints are given as [min]
    (inclusive) and [max] (exclusive). If [pin] is provided, a
    {{:https://opam.ocaml.org/doc/Manual.html#opamfield-pin-depends}
    pin-depends} is generated. *)

val name : t -> string
(** [name t] is [t]'s opam name. *)

val pin : t -> string option
(** [pin t] is [Some r] iff [t] is pinned to the repository [r]. *)

val build_dependency : t -> bool
(** [build_dependency t] is [true] iff [t] is a build-time dependency. *)

val libraries : t -> string list
(** [libraries t] is the set of libraries (and sub-libraries) used in the
    package [t]. For most packages, it will only contain one library whose name
    is [name t]. *)

val max_versions : t -> string list
(** [max_versions] is the set of maximum versions of [t] which are required. *)

val min_versions : t -> string list
(** [min_versions] is the set minimum versions of [t] which are required. *)

val merge : t -> t -> t option
(** [merge x y] is merges the information of [x] and [y]. The result is [None]
    if [opam x != opam y]. *)

val pp : ?surround:string -> t Fmt.t
(** [pp] is the pretty-printer for packages. *)
