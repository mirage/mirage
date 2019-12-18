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

(** Application builder. *)

open Functoria

(** {1 Useful module implementations} *)

val noop: job impl
(** [noop] is an implementation of {!Functoria.job} that holds no
    state, does nothing and has no dependency. *)

type argv
(** The type for command-line arguments, similar to the usual
    [Sys.argv]. *)

val argv: argv typ
(** [argv] is a value representing {!argv} module types. *)

val sys_argv: argv impl
(** [sys_argv] is a device providing command-line arguments by using
    {!Sys.argv}. *)

val keys: argv impl -> job impl
(** [keys a] is an implementation of {!Functoria.job} that holds the
    parsed command-line arguments. *)

type info
(** The type for application about the application being built. *)

val info: info typ
(** [info] is a value representing {!info} module types. *)

val app_info: ?type_modname:string -> ?gen_modname:string -> unit -> info impl
(** [app_info] is the module implementation whose state contains all
    the information available at configure-time. The type of the
    generated value lives in the module [type_modname]: if not set, it
    is [Functoria_info]. The value is stored into a generated module
    name [gen_modname]: if not set, it is [Info_gen]. *)

(** {1 Builders} *)

(** [S] is the signature that application builders have to provide. *)
module type S = sig

  open Functoria

  val prelude: string
  (** Prelude printed at the beginning of [main.ml].

      It should put in scope:

      - a [run] function of type ['a t -> 'a]
      - a [return] function of type ['a -> 'a t]
      - a [>>=] operator of type ['a t -> ('a -> 'b t) -> 'b t]
  *)

  val name: string
  (** Name of the custom DSL. *)

  val packages: package list
  (** The packages to load when compiling the configuration file. *)

  val ignore_dirs: string list
  (** Directories to ignore when compiling the configuration file. *)

  val version: string
  (** Version of the custom DSL. *)

  val create: job impl list -> job impl
  (** [create jobs] is the top-level job in the custom DSL which will
      execute the given list of [job]. *)

end

module Make (P: S): sig

  open Functoria

  (** Configuration builder: stage 1 *)

  val run: unit -> unit
  (** Run the configuration builder. This should be called exactly once
      to run the configuration builder: command-line arguments will be
      parsed, and some code will be generated and compiled. *)

  val run_with_argv:
    ?help_ppf:Format.formatter -> ?err_ppf:Format.formatter ->
    string array -> unit
  (** [run_with_argv a] is the same as {!run} but parses [a] instead
      of the process command line arguments. It also allows to set
      the error and help channels using [help_ppf] and [err_ppf]. *)


  (** Configuration module: stage 2 *)

  val register:
    ?packages:package list ->
    ?keys:key list ->
    ?init:job impl list ->
    string -> job impl list -> unit
  (** [register name jobs] registers the application named by [name]
      which will execute the given [jobs]. Same optional arguments as
      {!Functoria.foreign}.

      [init] is the list of job to execute before anything else (such
      as command-line argument parsing, log reporter setup, etc.). The
      jobs are always executed in the sequence specified by the
      caller. *)
end

module type DSL = sig

  type 'a typ = 'a Functoria.typ =
    | Type    : 'a -> 'a typ
    | Function: 'b typ * 'c typ -> ('b -> 'c) typ

  val typ: 'a -> 'a typ
  (** [type t] is a value representing the module type [t]. *)

  val (@->): 'a typ -> 'b typ -> ('a -> 'b) typ
  (** Construct a functor type from a type and an existing functor
      type. This corresponds to prepending a parameter to the list of
      functor parameters. For example:

      {[ kv_ro @-> ip @-> kv_ro ]}

      This describes a functor type that accepts two arguments -- a
      [kv_ro] and an [ip] device -- and returns a [kv_ro].
  *)

  type job = Functoria.job
  (** Type for job values. *)

  val job: job typ
  (** [job] is the signature for user's application main module. *)

  type 'a impl = 'a Functoria.impl
  (** The type for values representing module implementations. *)

  val ($): ('a -> 'b) impl -> 'a impl -> 'b impl
  (** [m $ a] applies the functor [m] to the module [a]. *)

  (** The type for abstract implementations. *)
  type abstract_impl = Functoria.abstract_impl

  val abstract: _ impl -> abstract_impl
  (** [abstract t] is [t] but with its type variable abstracted. Useful
      for dependencies. *)

  type key = Functoria.key
  (** The type for command-line keys. See {!Functoria_key.t}. *)

  type context = Functoria.context
  (** The type for keys' parsing context. See {!Functoria_key.context}. *)

  type 'a value = 'a Functoria.value
  (** The type for values parsed from the command-line. See
      {!Functoria_key.value}. *)

  val if_impl: bool value -> 'a impl -> 'a impl -> 'a impl
  (** [if_impl v impl1 impl2] is [impl1] if [v] is resolved to true and
      [impl2] otherwise. *)

  val match_impl: 'b value -> default:'a impl -> ('b * 'a impl) list ->  'a impl
  (** [match_impl v cases ~default] chooses the implementation amongst
      [cases] by matching the [v]'s value. [default] is chosen if no
      value matches. *)

  type package = Functoria.package
  (** The type of a package *)

  val package :
    ?build:bool ->
    ?sublibs:string list ->
    ?ocamlfind:string list ->
    ?min:string ->
    ?max:string ->
    ?pin:string ->
    string -> package
  (** [package ~build ~sublibs ~ocamlfind ~min ~max ~pin opam] is a [package].  [Build]
      indicates a build-time dependency only, defaults to [false]. The ocamlfind
      name is by default the same as [opam], you can specify [~sublibs] to add
      additional sublibraries (e.g. [~sublibs:["mirage"] "foo"] will result in the
      findlib names [ ["foo"; "foo.mirage"] ].  In case the findlib name is
      disjoint (or empty), use [~ocamlfind].  Specifying both [~ocamlfind] and
      [~sublibs] leads to an invalid argument.  Version constraints are given as
      [min] (inclusive) and [max] (exclusive).  If [pin] is provided, a
      {{:https://opam.ocaml.org/doc/Manual.html#opamfield-pin-depends}pin-depends}
      is generated. *)

  (** {1:app Application Builder}

      Values of type {!impl} are tied to concrete module implementation
      with the {!foreign} construct. Module implementations of type
      {!job} can then be {{!Functoria_app.Make.register}registered} into
      an application builder. The builder is in charge if parsing the
      command-line arguments and of generating code for the final
      application. See {!Functoria_app} for details. *)

  val foreign:
    ?packages:package list ->
    ?keys:key list ->
    ?deps:abstract_impl list ->
    string -> 'a typ -> 'a impl
  (** [foreign name typ] is the module [name], having the module type
      [typ].

      {ul
      {- If [packages] is set, then the given packages are
         installed before compiling the current application.}
      {- If [keys] is set, use the given {{!Key.key}keys} to
         parse at configure and runtime the command-line arguments
         before calling [name.connect].}
      {- If [deps] is set, the given list of {{!abstract_impl}abstract}
         implementations is added as data-dependencies: they will be
         initialized before calling [name.connect]. }
      }

      For a more flexible definition of packages, or for a custom configuration
      step, see the {!configurable} class type and the {!class:foreign} class.
  *)

  (** Signature for configurable module implementations. A
      [configurable] is a module implementation which contains a runtime
      state which can be set either at configuration time (by the
      application builder) or at runtime, using command-line
      arguments. *)
  class type ['ty] configurable = object

    method ty: 'ty typ
    (** [ty] is the module type of the configurable. *)

    method name: string
    (** [name] is the unique variable name holding the runtime state of
        the configurable. *)

    method module_name: string
    (** [module_name] is the name of the module implementing the
        configurable. *)

    method packages: package list value
    (** [packages] is the list of OPAM packages which needs to be
        installed before compiling the configurable. *)

    method connect: Info.t -> string -> string list -> string
    (** [connect info mod args] is the code to execute in order to
        initialize the state associated with the module [mod] (usually
        calling [mod.connect]) with the arguments [args], in the context
        of the project information [info]. *)

    method configure: Info.t -> (unit, Rresult.R.msg) result
    (** [configure info] is the code to execute in order to configure
        the device.  During the configuration phase, the specficied
        {!packages} might not yet be there.  The code might involve
        generating more OCaml code, running shell scripts, etc. *)

    method build: Info.t -> (unit, Rresult.R.msg) result
    (** [build info] is the code to execute in order to build
        the device.  During the build phase, you can rely that all
        {!packages} are installed (via opam).  The code might involve
        generating more OCaml code (crunching directories), running
        shell scripts, etc. *)

    method clean: Info.t -> (unit, Rresult.R.msg) result
    (** [clean info] is the code to clean-up what has been generated
        by {!build} and {!configure}. *)

    method keys: key list
    (** [keys] is the list of command-line keys to set-up the
        configurable. *)

    method deps: abstract_impl list
    (** [deps] is the list of {{!abstract_impl} abstract
        implementations} that must be initialized before calling
        {!connect}. *)

  end

  val impl: 'a configurable -> 'a impl
  (** [impl c] is the implementation of the configurable [c]. *)

  (** [base_configurable] pre-defining many methods from the
      {!configurable} class. To be used as follow:

      {[
        let time_conf = object
          inherit base_configurable
          method ty = time
          method name = "time"
          method module_name = "OS.Time"
        end
      ]}
  *)
  class base_configurable: object
    method packages: package list value
    method keys: key list
    method connect: Info.t -> string -> string list -> string
    method configure: Info.t -> (unit, Rresult.R.msg) result
    method build: Info.t -> (unit, Rresult.R.msg) result
    method clean: Info.t -> (unit, Rresult.R.msg) result
    method deps: abstract_impl list
  end

  class ['a] foreign:
    ?packages:package list ->
    ?keys:key list ->
    ?deps:abstract_impl list ->
    string -> 'a typ -> ['a] configurable
    (** This class can be inherited to define a {!configurable} with an API
        similar to {!foreign}.

        In particular, it allows dynamic packages. Here is an example:
        {[
          let main = impl @@ object
              inherit [_] foreign
                  "Unikernel.Main" (console @-> job)
              method packages = Key.(if_ is_xen)
                  [package ~sublibs:["xen"] "vchan"]
                  [package ~sublibs:["lwt"] "vchan"]
            end
        ]}
    *)
end

(** {1 Misc} *)

(** Name helpers. *)
module Name: sig

  val ocamlify: string -> string
  (** [ocamlify n] is an OCaml identifier looking very much like [n],
      but where invalid characters have been removed or replaced: all
      characters outside of ['a'-'z''A'-'Z''0''9''_''-'], and
      replacing '-' with '_'.  If the resulting string starts with a
      digit or is empty then it raises [Invalid_argument]. *)

  val create: string -> prefix:string -> string
  (** [name key ~prefix] is an deterministic name starting by
      [prefix]. The name is derived from [key].  *)

end

(** Code generation helpers. *)
module Codegen: sig

  val generated_header: ?argv:string array -> ?time:Ptime.t -> unit -> string

  val append:
    Format.formatter -> ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a

  val newline: Format.formatter -> unit

  val set_main_ml: string -> unit
  (** Define the current main file. *)

  val append_main: ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a
  (** Add some string to [main.ml]. *)

  val newline_main: unit -> unit
  (** Add a newline to [main.ml]. *)

end

module Cli = Cli
