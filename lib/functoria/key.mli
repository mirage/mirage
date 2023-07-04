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

(** Configuration and runtime command-line arguments. *)

(** Cross-stage command-line arguments. *)
module Arg : sig
  (** Terms for cross-stage arguments.

      This module extends
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html}
        Cmdliner.Arg} to allow MetaOCaml-style typed cross-stage persistency of
      command-line arguments. *)

  (** {1 Argument converters} *)

  type 'a serialize = Format.formatter -> 'a -> unit
  (** The type for command-line argument serializers. A value of type
      ['a serialize] generates a syntactically valid OCaml representation which
      evaluates to a value of type ['a]. *)

  type 'a runtime_conv = string
  (** The type for command-line argument converters used at runtime. A value of
      type ['a runtime_conv] is a symbol name of type
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html#type-conv}
        Cmdliner.Arg.conv}. *)

  type 'a converter
  (** The type for argument converters. *)

  val conv :
    conv:'a Cmdliner.Arg.conv ->
    serialize:'a serialize ->
    runtime_conv:'a runtime_conv ->
    'a converter
  (** [conv c s r] is the argument converter using [c] to convert user strings
      into OCaml value, [s] to convert OCaml values into strings interpretable
      as OCaml expressions, and the function named [r] to convert user strings
      into OCaml values at runtime. *)

  val string : string converter
  (** [string] converts strings. *)

  val bool : bool converter
  (** [bool] converts booleans. *)

  val int : int converter
  (** [int] converts integers. *)

  val int64 : int64 converter
  (** [int64] converts 64-bits integers. *)

  val list : ?sep:char -> 'a converter -> 'a list converter
  (** [list t] converts lists of [t]s. *)

  val pair : ?sep:char -> 'a converter -> 'b converter -> ('a * 'b) converter
  (** [pair a b] converts [a] and [b] to a pair of [a, b]. *)

  val some : 'a converter -> 'a option converter
  (** [some t] converts [t] options. *)

  (** {1 Arguments and their information} *)

  type 'a t
  (** The type for arguments holding data of type ['a]. *)

  type info
  (** The type for information about cross-stage command-line arguments. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html#arginfo}
        Cmdliner's arguments}. *)

  val info :
    ?docs:string ->
    ?docv:string ->
    ?doc:string ->
    ?env:string ->
    string list ->
    info
  (** Define cross-stage information for an argument. See
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html#type-info}
        Cmdliner.Arg.info}. If not set, [docs] is ["UNIKERNEL PARAMETERS"]. *)

  (** {1 Optional Arguments} *)

  type stage = [ `Configure | `Run ]
  (** The type for specifying at which stage an argument is available.

      - [`Configure] means that the argument is read on the command-line at
        configuration-time.
      - [`Run] means that the argument is read on the command-line at runtime. *)

  val opt : ?stage:stage -> 'a converter -> 'a -> info -> 'a t
  (** [opt conv v i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html#val-opt}
        Cmdliner.Arg.opt} but for cross-stage optional command-line arguments.
      If not set, [stage] is [`Configure]. *)

  val required : ?stage:stage -> 'a converter -> info -> 'a option t
  (** [required conv i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html#val-required}
        Cmdliner.Arg.required} but for cross-stage required command-line
      arguments. If not set, [stage] is [`Configure]. *)

  val flag : ?stage:stage -> info -> bool t
  (** [flag i] is similar to
      {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html#val-flag}
        Cmdliner.Arg.flag} but for cross-stage command-line flags. If not set,
      [stage] is [`Configure]. *)

  val opt_all : ?stage:stage -> 'a converter -> info -> 'a list t
end

(** {1 Configuration Keys} *)

type 'a key
(** The type for configuration keys. Keys are used to retrieve the cross-stage
    values they are holding (by indexing contents in the autogenerated
    [Bootgen_var] module) but also to parameterize the choice of
    {{!Functoria.if_impl} module implementation}. *)

val create : string -> 'a Arg.t -> 'a key
(** [create n a] is the key named [n] whose contents is determined by parsing
    the command-line argument [a]. *)

(** {1 Configuration Values} *)

type +'a value
(** The type for configure-time and run-time values. Values are either {!pure}
    or obtained by composing other values. Values might have {{!deps} data
    dependencies}, which form an (implicit) directed and acyclic graph that need
    to be evaluated. *)

val pure : 'a -> 'a value
(** [pure x] is a value without any dependency. *)

val ( $ ) : ('a -> 'b) value -> 'a value -> 'b value
(** [f $ v] is is the value resulting from the application of [f]'value to [v]'s
    value. [$] is the usual {i app} operator for
    {{:http://dx.doi.org/10.1017/S0956796807006326} applicative functor}. *)

val map : ('a -> 'b) -> 'a value -> 'b value
(** [map f v] is [pure f $ v]. *)

val if_ : bool value -> 'a -> 'a -> 'a value
(** [if_ v x y] is [map (fun b -> if b then x else y) v]. *)

val match_ : 'a value -> ('a -> 'b) -> 'b value
(** [match_ v pattern] is [map pattern v]. *)

val default : 'a value -> 'a
(** [default v] returns the default value for [v]. *)

val value : 'a key -> 'a value
(** [value k] is the value parsed by [k]. *)

(** {1 Abstract Keys} *)

type t
(** The type for abstract {{!type:key} keys}. *)

val name : t -> string
(** [name t] is the string given as [t]'s name when [t] was created. *)

val v : 'a key -> t
(** [v k] is the [k] with its type hidden. *)

val equal : t -> t -> bool
(** [equal] is the equality function of untyped keys. *)

val hash : t -> int
(** [hash] is the hash function for untyped keys. *)

val compare : t -> t -> int
(** [compare] compares untyped keys. *)

val pp : t Fmt.t
(** [pp fmt k] prints the name of [k]. *)

(** [Set] implements sets over [t] elements. *)
module Set : sig
  include Set.S with type elt = t

  val pp : t Fmt.t
  (** [pp] pretty-prints sets of keys. *)
end

val of_deps : Set.t -> unit value
(** [of_deps keys] is a value with [keys] as data-dependencies. *)

val deps : 'a value -> Set.t
(** [deps v] are [v]'s data-dependencies. *)

val pp_deps : 'a value Fmt.t
(** [pp_deps fmt v] prints the name of the dependencies of [v]. *)

(** {1 Stages} *)

val is_runtime : t -> bool
(** [is_runtime k] is true if [k]'s stage is [`Run]. *)

val is_configure : t -> bool
(** [is_configure k] is true if [k]'s stage is [`Configure]. *)

val filter_stage : Arg.stage -> Set.t -> Set.t
(** [filter_stage s ks] is [ks] but with only keys available at stage [s]. *)

(** {1 Parsing context} *)

type context := Context.t
(** The type for values holding parsing context. *)

val add_to_context : 'a key -> 'a -> context -> context
(** Add a binding to a context. *)

val context : Set.t -> context Cmdliner.Term.t
(** [context ks] is a [Cmdliner]
    {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Term/index.html#type-t}
      term} that evaluates into a parsing context for command-line arguments. *)

val mem : context -> 'a value -> bool
(** [mem c v] is [true] iff all the dependencies of [v] have been evaluated. *)

val peek : context -> 'a value -> 'a option
(** [peek c v] is [Some x] if [mem v] and [None] otherwise. *)

val eval : context -> 'a value -> 'a
(** [eval c v] evaluates [v] in [c]'s context, using default values if
    necessary. *)

val get : context -> 'a key -> 'a
(** [get c k] is [k]'s value in [c]'s context. If [k] is not present in [c], it
    is [k]'s default value.*)

val find : context -> 'a key -> 'a option
(** [find c k] is [k]'s value in [c]'s context or [None] if [k] is not present
    in [c]. *)

val pps : context -> Set.t Fmt.t
(** [pps c fmt ks] prints the keys [ks] using the context [c] to get their
    value. *)

(** {1 Code Serialization} *)

val ocaml_name : t -> string
(** [ocaml_name k] is the ocaml name of [k]. *)

val serialize_call : t Fmt.t
(** [serialize_call fmt k] outputs [Key_gen.n ()] to [fmt], where [n] is [k]'s
    {{!ocaml_name} OCaml name}. *)

val serialize : context -> t Fmt.t
(** [serialize ctx ppf k] outputs the [Cmdliner] runes to parse command-line
    arguments represented by [k] at runtime. *)

(**/**)

val module_name : string
(** Name of the generated module containing the keys. *)
