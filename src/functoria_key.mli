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
  (** {1 Cross-stage argument converters}

      This module extends
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html}
      Cmdliner.Arg} to allow MetaOCaml-style typed cross-stage
      persistency of command-line arguments. *)

  type 'a converter
  (** The type for argument converters. *)

  val conv:
    'a Cmdliner.Arg.converter -> (Format.formatter -> 'a -> unit) -> string ->
    'a converter
  (** [conv conf emit run] is the argument converter using [conf] to
      convert argument into OCaml value, [emit] to convert OCaml
      values into interpretable strings, and the function named [run]
      to transform these strings into OCaml values again. See
      {!conv_at_configure}, {!conv_emit} and {!conv_at_runtime} for
      details.*)

  (** {2 Predefined Converters} *)

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

  (** {2 Accessors} *)

  val conv_at_configure: 'a converter -> 'a Cmdliner.Arg.converter
  (** [conv_at_configure t] is the converter of configuration time's
      command-line arguments into OCaml values. *)

  val conv_emit: 'a converter -> Format.formatter -> 'a -> unit
  (** [conv_emit] allows to persist OCaml values across stages, ie. it
      takes values (which might be parsed with {!conv_at_configure} at
      configuration time) and produce a valid string representation
      which can be used at runtime, once the generated code is
      compiled. *)

  val conv_at_runtime: 'a converter -> string
  (** [conv_at_runtime] is the name of the function called at runtime
      to parse the command-line arguments. Usually, it is a
      [Cmdliner]'s combinator such as {i Cmdliner.Arg.string}. *)

  (** {1 Information} *)

  type info
  (** The type for information about cross-stage command-line
      arguments. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#arginfo}
      Cmdliner.Arg}.*)

  val info:
    ?docs:string -> ?docv:string -> ?doc:string -> ?env:string ->
    string list -> info
  (** Define cross-stage information for an argument. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#TYPEinfo}
      Cmdliner.Arg.info}.*)

  val info_at_configure: info -> Cmdliner.Arg.info
  (** [cmdliner_info i] is the projection of [i] to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#TYPEinfo}
      Cmdliner.Arg.info}. *)

  val info_emit: Format.formatter -> info -> unit
  (** [info_emit] allows to persist information about command-line
      arguments across stages. *)

end

type +'a value
(** The type for configure and runtime values. Values can be parsed
    from the command-line at configure or runtime, or can be provided
    at configuration time. A value might have evaluation dependencies,
    provided as a set of {{!key}keys}: a value is always evaluated
    after its dependencies.

    FIXME(samoht): example
*)

val pure: 'a -> 'a value
(** [pure x] is a value without any dependency. *)

val app: ('a -> 'b) value -> 'a value -> 'b value
(** [app f x] is the value resulting from the application of [f] to [v].
    Its dependencies are the union of the dependencies. *)

val ($): ('a -> 'b) value -> 'a value -> 'b value
(** [f $ v] is [app f v]. *)

val map: ('a -> 'b) -> 'a value -> 'b value
(** [map f v] is [pure f $ v]. *)

val pipe: 'a value -> ('a -> 'b) -> 'b value
(** [pipe v f] is [map f v]. *)

val if_: bool value -> 'a -> 'a -> 'a value
(** [if_ v x y] is [pipe v @@ fun b -> if b then x else y]. *)

val default: 'a value -> 'a
(** [default v] returns the default value for [v]. *)

(** {1 Keys} *)

type 'a key
(** The type for configuration keys. Keys are dynamic values that can
    be used to

    {ul
    {- Set {{!value}values} at configure and runtime by parsing
       arguments on the command line.}
    {- Switch implementation dynamically, using {!Functoria_dsl.if_impl}.
       FIXME(samoht): not sure what this mean (yet)}
    }

    Keys' content is made persistent by emitting code in module called
    [Bootvar_gen]. FIXME(implementation details?)
*)

val value: 'a key -> 'a value
(** [value k] is the value parsed by [k]. *)

type stage = [
  | `Configure
  | `Run
  | `Both
]
(** The type for specifying at which stage a key is available.

    {ul

    {- [`Configure] means that the key's value is read on the
       command-line at configuration-time and is available in the
       [Bootvar_gen] module at runtime.}
    {- [`Run] means that the key's value is read on the command-line
       at runtime.}
    {- [`Both] means that the key's value is read on the command-line
       both at configuration-time and runtime. If the keys is present
       on the command-line at configuration-time it is available in
       the [Bootvar_gen] module at runtime.}
    }
*)

val create:
  ?stage:stage -> doc:Arg.info -> default:'a -> string -> 'a Arg.converter ->
  'a key
(** [create ~doc ~stage ~default name conv] creates a new
    configuration key with docstring [doc], default value [default],
    name [name] and type descriptor [desc]. Default [stage] is
    [`Both].  It is an error to use more than one key with the same
    [name]. *)

val flag: ?stage:stage -> doc:Arg.info -> string -> bool key
(** [flag ~stage ~doc name] creates a new flag. A flag is a key that doesn't
    take argument. The boolean value represents if the flag was passed
    on the command line.
*)

type t
(** The type for untyped keys. *)

val v: 'a key -> t
(** [v key] is [key] by with all type information erased. This allows
    to put them in a set/list. *)

val pp: t Fmt.t
(** [pp fmt k] prints the name of [k]. *)

module Set: Set.S with type elt = t
(** Sets of keys. *)

val with_deps: keys:Set.t -> 'a value -> 'a value
(** [with_deps deps v] is the value [v] with added dependencies. *)

val deps: 'a value -> Set.t
(** [deps v] is the dependencies of [v]. *)

val pp_deps: 'a value Fmt.t
(** [pp_deps fmt v] prints the name of the dependencies of [v]. *)

(** {1 Stages} *)

val is_runtime: t -> bool
(** [is_runtime k] is true if [k]'s stage is [`Run] or [`Both]. *)

val is_configure: t -> bool
(** [is_configure k] is true if [k]'s stage is [`Configure] or [`Both]. *)

val filter_stage: stage:stage -> Set.t -> Set.t
(** [filter_stage ~stage set] filters [set] with the appropriate keys. *)

(** {1 Proxy} *)

(** Setters allow to set other keys. *)
module Setters: sig

  type 'a t
  (** The type for key setters. *)

  val empty: 'a t
  (** [empty] is the empty setter. *)

  val add: 'b key -> ('a -> 'b option) -> 'a t -> 'a t
  (** [add k f setters] Add a new setter to [setters]. It will set [k]
      to the value generated by [f]. If [f] returns [None], no value
      is set. *)

end

val proxy: doc:Arg.info -> setters:bool Setters.t -> string -> bool key
(** [proxy ~doc ~setters name] creates a new flag that will call [setters]
    when enabled.

    Proxies are only available during configuration.
*)

val setters: t -> Set.t
(** [setters k] returns the set of keys for which [k] has a setter. *)

(** {1 Key resolution} *)

type map
(** The type for parsed command-line arguments. *)

val term: ?stage:stage -> Set.t -> map Cmdliner.Term.t
(** [term l] is a [Cmdliner.Term.t] that, when evaluated, sets the value of the
    the keys in [l]. *)

val term_value: ?stage:stage -> 'a value -> 'a Cmdliner.Term.t
(** [term_value v] is [term @@ deps v] and returns the content of [v]. *)

val is_resolved: map -> 'a value -> bool
(** [is_reduced map v] returns [true] iff all the dependencies of [v] have
    been resolved. *)

val peek: map -> 'a value -> 'a option
(** [peek map v] returns [Some x] if [v] has been resolved to [x]
    and [None] otherwise. *)

val eval: map -> 'a value -> 'a
(** [eval map v] resolves [v], using default values if necessary. *)

val get: map -> 'a key -> 'a
(** [get map k] resolves [k], using default values if necessary. *)

val pp_map: map -> Set.t Fmt.t
(** [pp_map map fmt set] prints the keys in [set] with the values in [map]. *)

(** {1 Code emission} *)

val ocaml_name: t -> string
(** [ocaml_name k] is the ocaml name of [k]. *)

val emit_call: t Fmt.t
(** [emit_call fmt k] prints the OCaml code needed to get the value of [k]. *)

val emit: map -> t Fmt.t
(** [emit fmt k] prints the OCaml code needed to define [k]. *)

(**/**)

val module_name: string
(** Name of the generated module containing the keys. *)
