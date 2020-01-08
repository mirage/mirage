(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
 * Copyright (c) 2015-2020 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** Information about the final application. *)

module Package = Functoria_package
module Key = Functoria_key

type t
(** The type for information about the final application. *)

val name: t -> string
(** [name t] is the name of the application. *)

val output: t -> string option
(** [output t] is the name of [t]'s output. Derived from {!name} if
    not set. *)

val with_output: t -> string -> t
(** [with_output t o] is similar to [t] but with the output set to
    [Some o]. *)

val build_dir: t -> Fpath.t
(** Directory in which the build is done. *)

val libraries: t -> string list
(** [libraries t] are the direct OCamlfind dependencies. *)

val package_names: t -> string list
(** [package_names t] are the opam package dependencies. *)

val packages: t -> Package.t list
(** [packages t] are the opam package dependencies by the project. *)

val keys: t -> Key.t list
(** [keys t] are the keys declared by the project. *)

val context: t -> Key.context
(** [parsed t] is a value representing the command-line argument
    being parsed. *)

(** [create context n r] contains information about the application
    being built. *)
val create:
  packages:Package.t list ->
  keys:Key.t list ->
  context:Key.context ->
  name:string ->
  build_dir:Fpath.t -> t

val pp: bool -> t Fmt.t

val opam: ?name:string -> t Fmt.t
(** [opam t] generates an opam file including all dependencies. If
    set, [name] will be used as package name, otherwise use
    {!name}. *)
