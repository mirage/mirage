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
    {{!main} module} implementations, specify the command-line {!type-key} that
    are required and {{!section-combinators} combine} all of them together using
    {{:http://dx.doi.org/10.1017/S0956796807006326} applicative} operators.

    The DSL expression is then compiled into an
    {{!section-app} application builder}, which will, once evaluated, produced
    the final portable and flexible application. *)

(** {1:combinators Combinators} *)

type 'a typ = 'a Type.t
(** The type for values representing module types. *)

val typ : 'a -> 'a typ
(** [type t] is a value representing the module type [t]. *)

val ( @-> ) : 'a typ -> 'b typ -> ('a -> 'b) typ
(** Construct a functor type from a type and an existing functor type. This
    corresponds to prepending a parameter to the list of functor parameters. For
    example:

    {[
      kv_ro @-> ip @-> kv_ro
    ]}

    This describes a functor type that accepts two arguments -- a [kv_ro] and an
    [ip] device -- and returns a [kv_ro]. *)

type 'a impl = 'a Impl.t
(** The type for values representing module implementations. *)

val ( $ ) : ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [m] to the module [a]. *)

type abstract_impl = Impl.abstract
(** Same as {!type-impl} but with hidden type. *)

val dep : 'a impl -> abstract_impl
(** [dep t] is the (build-time) dependency towards [t]. *)

(** {1:keys Keys} *)

type 'a key = 'a Key.key
(** The type for configure-time command-line arguments. *)

type 'a runtime_arg = 'a Runtime_arg.arg
(** The type for runtime command-line arguments. *)

val runtime_arg :
  pos:string * int * int * int ->
  ?packages:Package.t list ->
  string ->
  Runtime_arg.t
(** [runtime_arg ~pos ?packages v] is the runtime argument pointing to the value
    [v]. [pos] is expected to be [__POS__]. [packages] specifies in which opam
    package the value [v] is defined. *)

type abstract_key = Key.t
(** The type for abstract keys. *)

type context = Context.t
(** The type for keys' parsing context. See {!module-Key.type-context}. *)

type 'a value = 'a Key.value
(** The type for values parsed from the command-line. See {!Key.type-value}. *)

val key : 'a key -> Key.t
(** [key k] is an untyped representation of [k]. *)

val if_impl : bool value -> 'a impl -> 'a impl -> 'a impl
(** [if_impl v impl1 impl2] is [impl1] if [v] is resolved to true and [impl2]
    otherwise. *)

val match_impl : 'b value -> default:'a impl -> ('b * 'a impl) list -> 'a impl
(** [match_impl v cases ~default] chooses the implementation amongst [cases] by
    matching the [v]'s value. [default] is chosen if no value matches. *)

(** {1:pkg Package dependencies}

    For specifying opam package dependencies, the type {!type-package} is used.
    It consists of the opam package name, the ocamlfind names, and optional
    lower and upper bounds. The version constraints are merged with other
    modules. *)

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
  ?pin_version:string ->
  string ->
  package
(** [package ~scope ~build ~sublibs ~libs ~min ~max ~pin opam] is a [package].
    [Build] indicates a build-time dependency only, defaults to [false]. The
    library name is by default the same as [opam], you can specify [~sublibs] to
    add additional sublibraries (e.g. [~sublibs:["mirage"] "foo"] will result in
    the library names [["foo"; "foo.mirage"]]. In case the library name is
    disjoint (or empty), use [~libs]. Specifying both [~libs] and [~sublibs]
    leads to an invalid argument. Version constraints are given as [min]
    (inclusive) and [max] (exclusive). If [pin] is provided, a
    {{:https://opam.ocaml.org/doc/Manual.html#opamfield-pin-depends}
     pin-depends} is generated, [pin_version] is ["dev"] by default. [~scope]
    specifies the installation location of the package. *)

(** {1:app Application Builder}

    Values of type {!type-impl} are tied to concrete module implementation with
    the {!device} and {!main} construct. Module implementations of type
    {!type-job} can then be {{!Functoria.Lib.Make.register} registered} into an
    application builder. The builder is in charge if parsing the command-line
    arguments and of generating code for the final application. See
    {!Functoria.Lib} for details. *)

type info = Info.t
(** The type for build information. *)

val main :
  ?pos:string * int * int * int ->
  ?packages:package list ->
  ?packages_v:package list value ->
  ?runtime_args:Runtime_arg.t list ->
  ?deps:abstract_impl list ->
  string ->
  'a typ ->
  'a impl
(** [main name typ] is the functor [name], having the module type [typ]. The
    connect code will call [<name>.start].

    - If [packages] or [packages_v] is set, then the given packages are
      installed before compiling the current application. *)

(** {1 Devices} *)

type 'a code = 'a Device.code

val code :
  pos:string * int * int * int ->
  ('a, Format.formatter, unit, 'b code) format4 ->
  'a

type 'a device = ('a, abstract_impl) Device.t

val of_device : 'a device -> 'a impl
(** [of_device t] is the implementation device [t]. *)

val impl :
  ?packages:package list ->
  ?packages_v:package list Key.value ->
  ?install:(Info.t -> Install.t) ->
  ?install_v:(Info.t -> Install.t Key.value) ->
  ?keys:Key.t list ->
  ?runtime_args:Runtime_arg.t list ->
  ?extra_deps:abstract_impl list ->
  ?connect:(info -> string -> string list -> 'a code) ->
  ?dune:(info -> Dune.stanza list) ->
  ?configure:(info -> unit Action.t) ->
  ?files:(info -> Fpath.t list) ->
  string ->
  'a typ ->
  'a impl
(** [impl ~packages ~packages_v ~install ~install_v ~keys ~runtime_args
     ~extra_deps ~connect ~dune ~configure ~files module_name module_type] is an
    implementation of the device constructed by the arguments. [packages] and
    [packages_v] are the dependencies (where [packages_v] is inside
    {!Key.value}). [install] and [install_v] are the install instructions (used
    in the generated opam file), [keys] are the configuration-time keys,
    [runtime_args] the arguments at runtime, [extra_deps] are a list of extra
    dependencies (other implementations), [connect] is the code emitted for
    initializing the device, [dune] are dune stanzas added to the build rule,
    [configure] are commands executed at the configuration phase, [files] are
    files to be added to the list of generated files, [module_name] is the name
    of the device module, and [module_type] is the type of the module. *)

(** {1 Jobs} *)

type job = Job.t
