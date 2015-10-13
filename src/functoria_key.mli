(*
 * Copyright (c) 2015 Nicolas Ojeda Bar <n.oje.bar@gmail.com>
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

(** Configuration and runtime command-line arguments. *)

(** Cross-stage command-line arguments. *)
module Arg: sig
  (** Terms for cross-stage arguments.

      This module extends
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html}
      Cmdliner.Arg} to allow MetaOCaml-style typed cross-stage
      persistency of command-line arguments. *)

  (** {1 Argument converters} *)

  type 'a emit = Format.formatter -> 'a -> unit
  (** The type for OCaml code emmiter. A value of type ['a emitter]
      generates valid OCaml code with type ['a]. *)

  type 'a runtime = string
  (** The type for {i raw} OCaml code. A value of type ['a code] can
      be interpreted as an OCaml value with type ['a]. *)

  type 'a converter = 'a Cmdliner.Arg.converter * 'a emit * 'a runtime
  (** The type for argument converters. A value of [(conv, emit,
      code)] of type ['a converter] is the argument converter using
      [conf] to convert argument into OCaml value, [emit] to convert
      OCaml values into interpretable strings, and the function named
      [run] to transform these strings into OCaml values again.

      {ul

      {- [conv] is the converter of configuration time's command-line
         arguments into OCaml values.}
      {- [emit] allows to persist OCaml values across stages, ie. it
         takes values (which might be parsed with [conv] at
         configuration time) and produce a valid string representation
         which can be used at runtime, once the generated code is
         compiled.}
      {- [run] is the name of the function called at runtime to parse
         the command-line arguments. Usually, it is a [Cmdliner]'s
         combinator such as {i Cmdliner.Arg.string}.}
      }

  *)

  val string: string converter
  (** [string] converts strings. *)

  val bool: bool converter
  (** [bool] converts booleans. *)

  val int: int converter
  (** [int] converts integers. *)

  val list: 'a converter -> 'a list converter
  (** [list t] converts lists of [t]s. *)

  val some: 'a converter -> 'a option converter
  (** [some t] converts [t] options. *)

  (** {1 Arguments and their information} *)

  type 'a t
  (** The type for arguments holding data of type ['a]. *)

  type info
  (** The type for information about cross-stage command-line
      arguments. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#arginfo}
      Cmdliner.Arg#TYPEinfo}. *)

  val info:
    ?docs:string -> ?docv:string -> ?doc:string -> ?env:string ->
    string list -> info
  (** Define cross-stage information for an argument. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#TYPEinfo}
      Cmdliner.Arg.info}.*)


  (** {1 Optional Arguments} *)

  (** The type for specifying at which stage an argument is available.

      {ul
      {- [`Configure] means that the argument is read on the
         command-line at configuration-time.}
      {- [`Run] means that the argument is read on the command-line at
         runtime.}
      {- [`Both] means that the argument is read on the command-line
         both at configuration-time and runt-ime.}
      } *)
  type stage = [
    | `Configure
    | `Run
    | `Both
  ]

  val opt: ?stage:stage -> 'a converter -> 'a -> info -> 'a t
  (** [opt conv v i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#VALopt}
      Cmdliner.Arg.opt} but for cross-stage optional command-line
      arguments. If not set, [stage] is [`Both]. *)

  val flag: ?stage:stage -> info -> bool t
  (** [flag i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#VALflag}
      Cmdliner.Arg.opt} but for cross-stage command-line flags. If not
      set, [stage] is [`Both]. *)

end

type +'a value
(** The type for configure-time and run-time values. Values can be
    parsed from the command-line at configure and/or runtime, or can
    be provided as OCaml values in the application configuration file
    (ie. {i config.ml}). *)

val pure: 'a -> 'a value
(** [pure x] is a value without any dependency. *)

val ($): ('a -> 'b) value -> 'a value -> 'b value
(** [f $ v] is is the value resulting from the application of
    [f]'value to [v]'s value. [$] is the usual {i app} operator for
    {{:http://dx.doi.org/10.1017/S0956796807006326}applicative
    functor}. *)

val map: ('a -> 'b) -> 'a value -> 'b value
(** [map f v] is [pure f $ v]. *)

val if_: bool value -> 'a -> 'a -> 'a value
(** [if_ v x y] is [map (fun b -> if b then x else y) v]. *)

val default: 'a value -> 'a
(** [default v] returns the default value for [v]. *)

(** {1 Configuration Keys} *)

type 'a key
(** The type for configuration keys. Keys form a directed and acyclic
    dynamic graph of dependent values that need to be evaluated in
    order to obtain {!values}. Vertices of the key graph hold
    {{!value}values}. Edges represent direct evaluation dependencies
    between values.

    Keys are used to retrieve the cross-stage values they are holding
    (by indexing contents in the autogenerated [Bootgen_var] module)
    but also to parametrize the choice of
    {{!Functoria_dsl.if_impl}module implementation}. *)


val create: string -> 'a Arg.t -> 'a key
(** [create n a] is the key named [n] whose contents is determined by
    parsing the command-line argument [a]. *)

val value: 'a key -> 'a value
(** [value k] is the value parsed by [k]. *)

type t
(** The type for untyped keys. *)

val compare: t -> t -> int
(** [compare] compares untyped keys. *)

val v: 'a key -> t
(** [v key] is [key] by with all type information erased. This allows
    to put them in a set/list. *)

val pp: t Fmt.t
(** [pp fmt k] prints the name of [k]. *)

val with_deps: keys:t list -> 'a value -> 'a value
(** [with_deps deps v] is the value [v] with added dependencies. *)

val deps: 'a value -> t list
(** [deps v] is the dependencies of [v]. *)

val pp_deps: 'a value Fmt.t
(** [pp_deps fmt v] prints the name of the dependencies of [v]. *)

(** {1 Stages} *)

val is_runtime: t -> bool
(** [is_runtime k] is true if [k]'s stage is [`Run] or [`Both]. *)

val is_configure: t -> bool
(** [is_configure k] is true if [k]'s stage is [`Configure] or [`Both]. *)

val filter_stage: Arg.stage -> t list -> t list
(** [filter_stage s ks] is [ks] but with only keys available at stage
    [s]. *)

(** {1 Alias}

    Alias allows to define virtual keys in terms of other keys at
    configuration time only. *)
module Alias: sig

  type 'a t
  (** The type for key alias. *)

  val add: 'b key -> ('a -> 'b option) -> 'a t -> 'a t
  (** [add k f a] set [a] as an alias for the key [k]: setting [a] on
      the command-line will set [k] to [f] applied to [a]'s value. If
      [f] returns [None], no value is set. *)

  val flag: Arg.info -> bool t
  (** [flag] is similar to {!Arg.flag} but defines configure-only
      command-line flag alias. Set [stage] to [`Configure]. *)

  val opt: 'a Arg.converter -> 'a -> Arg.info -> 'a t
  (** [opt] is similar to {!Arg.opt} but defines configure-only
      optional command-line arguments. Set [stage] to [`Configure]. *)

end

val alias: string -> 'a Alias.t -> 'a key
(** Similar to {!create} but for command-line alias. *)

val aliases: t -> t list
(** [aliases t] is the list of [t]'s aliases. *)

(** {1 Parsing context} *)

type context
(** The type for values holding parsing context. *)

val parse: ?stage:Arg.stage -> t list -> context Cmdliner.Term.t
(** [parse ks] is a [Cmdliner]
    {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Term.html#TYPt}
    term} that evaluates into a parsing context for the keys [ks]. *)

val parse_value: ?stage:Arg.stage -> 'a value -> 'a Cmdliner.Term.t
(** [parse_value v] is [parse @@ deps v] and returns the content of
    [v]. *)

val is_parsed: context -> 'a value -> bool
(** [is_parsed p v] returns [true] iff all the dependencies of [v]
    have been parsed. *)

val peek: context -> 'a value -> 'a option
(** [peek p v] returns [Some x] if [v] has been resolved to [x] and
    [None] otherwise. *)

val eval: context -> 'a value -> 'a
(** [eval p v] resolves [v], using default values if necessary. *)

val get: context -> 'a key -> 'a
(** [get p k] resolves [k], using default values if necessary. *)

val pp_parsed: context -> t list Fmt.t
(** [pp_parsed p fmt set] prints the keys in [set] using the context
    [c]. *)

(** {1 Code emitting} *)

val ocaml_name: t -> string
(** [ocaml_name k] is the ocaml name of [k]. *)

val emit_call: t Fmt.t
(** [emit_call fmt k] prints the OCaml code needed to persist [k]s'
    value. FIXME(samoht): doc unclear *)

val emit: context -> t Fmt.t
(** [emit c fmt k] prints the OCaml code needed to persist
    [k]. FIXME(samoht): doc unclear *)

(**/**)

val module_name: string
(** Name of the generated module containing the keys. *)
