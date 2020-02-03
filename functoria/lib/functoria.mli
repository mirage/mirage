(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

(** The Functoria DSL.

    The Functoria DSL allows users to describe how to create portable and
    flexible applications. It allows to pass application parameters easily using
    command-line arguments either at configure-time or at runtime.

    Users of the Functoria DSL composes their application by defining a list of
    {{!foreign} module} implementations, specify the command-line {!keys} that
    are required and {{!combinators} combine} all of them together using
    {{:http://dx.doi.org/10.1017/S0956796807006326} applicative} operators.

    The DSL expression is then compiled into an {{!app} application builder},
    which will, once evaluated, produced the final portable and flexible
    application. *)

open Rresult

(** {1:combinators Combinators} *)

type 'a typ = 'a Functoria_type.t
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

type 'a impl
(** The type for values representing module implementations. *)

val ( $ ) : ('a -> 'b) impl -> 'a impl -> 'b impl
(** [m $ a] applies the functor [m] to the module [a]. *)

(** The type for abstract implementations. *)
type abstract_impl = Abstract : _ impl -> abstract_impl

val abstract : _ impl -> abstract_impl
(** [abstract t] is [t] but with its type variable abstracted. Useful for
    dependencies. *)

(** {1:keys Keys} *)

type abstract_key = Functoria_key.t
(** The type for command-line keys. See {!Functoria_key.t}. *)

type context = Functoria_key.context
(** The type for keys' parsing context. See {!Functoria_key.context}. *)

type 'a value = 'a Functoria_key.value
(** The type for values parsed from the command-line. See
    {!Functoria_key.value}. *)

val if_impl : bool value -> 'a impl -> 'a impl -> 'a impl
(** [if_impl v impl1 impl2] is [impl1] if [v] is resolved to true and [impl2]
    otherwise. *)

val match_impl : 'b value -> default:'a impl -> ('b * 'a impl) list -> 'a impl
(** [match_impl v cases ~default] chooses the implementation amongst [cases] by
    matching the [v]'s value. [default] is chosen if no value matches. *)

(** The signature for run-time and configure-time command-line keys. *)
module type KEY =
  module type of Functoria_key
    with type 'a Arg.converter = 'a Functoria_key.Arg.converter
     and type 'a Arg.t = 'a Functoria_key.Arg.t
     and type Arg.info = Functoria_key.Arg.info
     and type 'a value = 'a Functoria_key.value
     and type 'a key = 'a Functoria_key.key
     and type t = Functoria_key.t
     and type Set.t = Functoria_key.Set.t
     and type 'a Alias.t = 'a Functoria_key.Alias.t
     and type context = Functoria_key.context

(** {1:pkg Package dependencies}

    For specifying opam package dependencies, the type {!package} is used. It
    consists of the opam package name, the ocamlfind names, and optional lower
    and upper bounds. The version constraints are merged with other modules. *)

module Package = Functoria_package

type package = Package.t
(** The type for packages. *)

val package :
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
    can then be {{!Functoria_app.Make.register} registered} into an application
    builder. The builder is in charge if parsing the command-line arguments and
    of generating code for the final application. See {!Functoria_app} for
    details. *)

val foreign :
  ?packages:package list ->
  ?packages_v:package list Functoria_key.value ->
  ?keys:abstract_key list ->
  ?deps:abstract_impl list ->
  string ->
  'a typ ->
  'a impl
(** Alias for {!main}, where [?extra_deps] has been renamed to [?deps]. *)

val main :
  ?packages:package list ->
  ?packages_v:package list Functoria_key.value ->
  ?keys:abstract_key list ->
  ?extra_deps:abstract_impl list ->
  string ->
  'a typ ->
  'a impl
(** [foreign name typ] is the functor [name], having the module type [typ]. The
    connect code will call [<name>.start].

    - If [packages] or [packages_v] is set, then the given packages are
      installed before compiling the current application.
    - If [keys] is set, use the given {{!Functoria_key.key} keys} to parse at
      configure and runtime the command-line arguments before calling
      [<name>.connect].
    - If [extra_deps] is set, the given list of {{!abstract_impl} abstract}
      implementations is added as data-dependencies: they will be initialized
      before calling [<name>.connect]. *)

module Info = Functoria_info

(** Signature for functoria devices. A [device] is a module implementation which
    contains a runtime state which can be set either at configuration time (by
    the application builder) or at runtime, using command-line arguments. *)
module Device : sig
  type 'a t
  (** The type for devices whose runtime state is of type ['a]. *)

  val module_type : 'a t -> 'a typ
  (** [module_type t] is [t]'s module type. *)

  val module_name : 'a t -> string
  (** [module_name t] is [t]'s module name. *)

  val packages : 'a t -> package list value
  (** [packages t] is the list of OPAM packages that are needed by [t].*)

  type 'a code = string
  (** The type for fragments of code of type ['a]. *)

  val connect : 'a t -> Info.t -> string -> string list -> 'a code
  (** [connect t info impl_name args] is the code to execute in order to create
      a new state (usually calling [<module_name t>.connect]) with the arguments
      [args], in the context of the project information [info]. The freshly
      created state will be made available in [var_name t] *)

  val configure : 'a t -> Info.t -> (unit, R.msg) result
  (** [configure t info] runs [t]'s configuration hooks. During the
      configuration phase, [packages t] might not yet be installed yet. The code
      might involve generating more OCaml code, running shell scripts, etc. *)

  val build : 'a t -> Info.t -> (unit, R.msg) result
  (** [build t info] runs the build hooks for [t] the device. During the build
      phase, you can rely on every [packages t] to be installed. The code might
      involve generating more OCaml code (crunching directories), running shell
      scripts, etc. *)

  val clean : 'a t -> Info.t -> (unit, R.msg) result
  (** [clean t info] runs [t]'s clean-up hooks. *)

  val keys : 'a t -> abstract_key list
  (** [keys t] is the list of command-line keys which can be used to configure
      [t]. *)

  val extra_deps : 'a t -> abstract_impl list
  (** [runtime_deps t] is the list of {{!abstract_impl} implementations} that
      must be initialized before running the code generated by [connect t]. *)

  val id : 'a t -> int
  (** [id t] is [t]'s unique identifier. Freshly generated for each call to
      {!v}. *)

  val v :
    ?packages:package list ->
    ?packages_v:package list Functoria_key.value ->
    ?keys:Functoria_key.t list ->
    ?extra_deps:abstract_impl list ->
    ?connect:(Info.t -> string -> string list -> 'a code) ->
    ?configure:(Info.t -> (unit, R.msg) result) ->
    ?build:(Info.t -> (unit, R.msg) result) ->
    ?clean:(Info.t -> (unit, R.msg) result) ->
    string ->
    'a typ ->
    'a t

  val start : string -> string list -> 'a code
  (** [start impl_name args] is the code [<impl_name>.start <args>]. *)

  val extend :
    ?packages:package list ->
    ?packages_v:package list value ->
    ?pre_configure:(Info.t -> (unit, R.msg) result) ->
    ?post_configure:(Info.t -> (unit, R.msg) result) ->
    ?pre_build:(Info.t -> (unit, R.msg) result) ->
    ?post_build:(Info.t -> (unit, R.msg) result) ->
    ?pre_clean:(Info.t -> (unit, R.msg) result) ->
    ?post_clean:(Info.t -> (unit, R.msg) result) ->
    'a t ->
    'a t

  val pp : 'a t Fmt.t
  (** [pp] is the pretty-printer for devices. *)

  val equal : 'a t -> 'b t -> bool
  (** [equal] is the equality function for devices. *)
end

val of_device : 'a Device.t -> 'a impl
(** [of_device t] is the implementation device [t]. *)

val impl :
  ?packages:package list ->
  ?packages_v:package list Functoria_key.value ->
  ?keys:Functoria_key.t list ->
  ?extra_deps:abstract_impl list ->
  ?connect:(Info.t -> string -> string list -> string) ->
  ?configure:(Info.t -> (unit, R.msg) result) ->
  ?build:(Info.t -> (unit, R.msg) result) ->
  ?clean:(Info.t -> (unit, R.msg) result) ->
  string ->
  'a typ ->
  'a impl
(** [impl ...] is [of_device @@ Device.v ...] *)

(** {1 Useful module implementations} *)

type job
(** Type for job values. *)

val job : job typ
(** [job] is the signature for user's application main module. *)

val noop : job impl
(** [noop] is an implementation of {!Functoria.job} that holds no state, does
    nothing and has no dependency. *)

type argv
(** The type for command-line arguments, similar to the usual [Sys.argv]. *)

val argv : argv typ
(** [argv] is a value representing {!argv} module types. *)

val sys_argv : argv impl
(** [sys_argv] is a device providing command-line arguments by using
    {!Sys.argv}. *)

val keys : argv impl -> job impl
(** [keys a] is an implementation of {!Functoria.job} that holds the parsed
    command-line arguments. *)

type info
(** The type for application about the application being built. *)

val info : info typ
(** [info] is a value representing {!info} module types. *)

val app_info :
  ?opam_deps:(string * string) list -> ?gen_modname:string -> unit -> info impl
(** [app_info] is the module implementation whose state contains all the
    information available at configure-time. The value is stored into a
    generated module name [gen_modname]: if not set, it is [Info_gen]. *)

(** {1 Sharing} *)

val hash : 'a impl -> int
(** [hash] is the hash function on implementations. FIXME(samoht) expand on how
    it works. *)

val equal : 'a impl -> 'a impl -> bool
(** [equal] is the equality over implementations. *)

module ImplTbl : Hashtbl.S with type key = abstract_impl
(** Hashtbl of implementations. *)

(**/**)

val explode :
  'a impl ->
  [ `App of abstract_impl * abstract_impl
  | `If of bool value * 'a impl * 'a impl
  | `Dev of 'a Device.t ]

module Type = Functoria_type
