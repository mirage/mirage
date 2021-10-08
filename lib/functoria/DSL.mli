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

(** The Functoria DSL allows users to describe how to create portable and
    flexible applications. It allows to pass application parameters easily using
    command-line arguments either at configure-time or at runtime.

    Users of the Functoria DSL composes their application by defining a list of
    {{!main} module} implementations, specify the command-line {!keys} that are
    required and {{!combinators} combine} all of them together using
    {{:http://dx.doi.org/10.1017/S0956796807006326} applicative} operators.

    The DSL expression is then compiled into an {{!app} application builder},
    which will, once evaluated, produced the final portable and flexible
    application. *)

(** {1:combinators Combinators} *)

type 'a typ = 'a Type.t
(** The type for values representing module types. *)

val typ : 'a -> 'a typ
(** [type t] is a value representing the module type [t]. *)

val ( @-> ) : 'a typ -> 'b typ -> ('a -> 'b) typ
(** Construct a functor type from a type and an existing functor type. This
    corresponds to prepending a parameter to the list of functor parameters. For
    example:

    {[ kv_ro @-> ip @-> kv_ro ]}

    This describes a functor type that accepts two arguments -- a [kv_ro] and an
    [ip] device -- and returns a [kv_ro]. *)

type 'a impl = 'a Impl.t
(** The type for values representing module implementations. *)

val ( $ ) : ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [m] to the module [a]. *)

type abstract_impl = Impl.abstract
(** Same as {!impl} but with hidden type. *)

val dep : 'a impl -> abstract_impl
(** [dep t] is the (build-time) dependency towards [t]. *)

val abstract : 'a impl -> abstract_impl
  [@@ocaml.deprecated "Use Functoria.dep."]

(** {1:keys Keys} *)

type 'a key = 'a Key.key
(** The type for command-line parameters. *)

type abstract_key = Key.t
(** The type for abstract keys. *)

type context = Key.context
(** The type for keys' parsing context. See {!Key.context}. *)

type 'a value = 'a Key.value
(** The type for values parsed from the command-line. See {!Key.value}. *)

val key : 'a key -> Key.t
(** [key k] is an untyped representation of [k]. *)

val if_impl : bool value -> 'a impl -> 'a impl -> 'a impl
(** [if_impl v impl1 impl2] is [impl1] if [v] is resolved to true and [impl2]
    otherwise. *)

val match_impl : 'b value -> default:'a impl -> ('b * 'a impl) list -> 'a impl
(** [match_impl v cases ~default] chooses the implementation amongst [cases] by
    matching the [v]'s value. [default] is chosen if no value matches. *)

(** {1:pkg Package dependencies}

    For specifying opam package dependencies, the type {!package} is used. It
    consists of the opam package name, the ocamlfind names, and optional lower
    and upper bounds. The version constraints are merged with other modules. *)

type package = Package.t
(** The type for opam packages. *)

type scope = Package.scope
(** Installation scope of a package. *)

val package :
  ?scope:scope ->
  ?build:bool ->
  ?sublibs:string list ->
  ?libs:string list ->
  ?min:string ->
  ?max:string ->
  ?pin:string ->
  string ->
  package
(** Same as {!Package.v} *)

(** {1:app Application Builder}

    Values of type {!impl} are tied to concrete module implementation with the
    {!device} and {!foreign} construct. Module implementations of type {!job}
    can then be {{!App.Make.register} registered} into an application builder.
    The builder is in charge if parsing the command-line arguments and of
    generating code for the final application. See {!App} for details. *)

type info = Info.t
(** The type for build information. *)

val foreign :
  ?packages:package list ->
  ?packages_v:package list value ->
  ?keys:abstract_key list ->
  ?deps:abstract_impl list ->
  string ->
  'a typ ->
  'a impl
(** Alias for {!main}, where [?extra_deps] has been renamed to [?deps]. *)

val main :
  ?packages:package list ->
  ?packages_v:package list value ->
  ?keys:abstract_key list ->
  ?extra_deps:abstract_impl list ->
  string ->
  'a typ ->
  'a impl
(** [foreign name typ] is the functor [name], having the module type [typ]. The
    connect code will call [<name>.start].

    - If [packages] or [packages_v] is set, then the given packages are
      installed before compiling the current application.
    - If [keys] is set, use the given {{!Key.key} keys} to parse at configure
      and runtime the command-line arguments before calling [<name>.connect].
    - If [extra_deps] is set, the given list of {{!abstract_impl} abstract}
      implementations is added as data-dependencies: they will be initialized
      before calling [<name>.connect]. *)

(** {1 Devices} *)

type 'a device = ('a, abstract_impl) Device.t

val of_device : 'a device -> 'a impl
(** [of_device t] is the implementation device [t]. *)

val impl :
  ?packages:package list ->
  ?packages_v:package list Key.value ->
  ?install:(Info.t -> Install.t) ->
  ?install_v:(Info.t -> Install.t Key.value) ->
  ?keys:Key.t list ->
  ?extra_deps:abstract_impl list ->
  ?connect:(info -> string -> string list -> string) ->
  ?dune:(info -> Dune.stanza list) ->
  ?configure:(info -> unit Action.t) ->
  ?files:(info -> Fpath.t list) ->
  string ->
  'a typ ->
  'a impl
(** [impl ...] is [of_device @@ Device.v ...] *)

(** {1 Jobs} *)

type job = Job.t
