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

(** Support for setting configuration parameters via the command-line.

    [Functoria_key] is used by the [Functoria] and [Functoria_tool] modules to:

    - Construct [Cmdliner.Term.t]'s corresponding to used configuration keys in
      order to be able to set them at compile-time (see {!Main.configure}).

    - Generate a [bootvar.ml] file during configuration containing necessary
      code to do the same at run-time. *)

module Desc : sig

  type 'a parser = string -> [ `Ok of 'a | `Error of string ]
  type 'a printer = Format.formatter -> 'a -> unit
  type 'a converter = 'a parser * 'a printer

  type 'a t

  val serializer : 'a t -> Format.formatter -> 'a -> unit
  val description :  'a t -> string
  val converter : 'a t -> 'a converter

  val create :
    serializer:(Format.formatter -> 'a -> unit) ->
    converter:'a converter ->
    description:string ->
    'a t

  val string : string t
  val bool : bool t
  val int : int t
  val list : 'a t -> 'a list t
  val option : 'a t -> 'a option t

  val from_converter : string -> 'a converter -> 'a t

end

module Doc : sig

  type t

  val create : ?docs:string -> ?docv:string -> ?doc:string -> string list -> t
  val to_cmdliner : t -> Cmdliner.Arg.info
  val emit : Format.formatter -> t -> unit

end



type stage = [
  | `Configure
  | `Run
  | `Both
]

type 'a key
(** The type of configuration keys that can be set on the command-line. *)

val create : ?doc:string -> ?stage:stage -> default:'a -> string -> 'a Desc.t -> 'a key
(** [create ~doc ~stage ~default name desc] creates a new configuration key with
    docstring [doc], default value [default], name [name] and type descriptor
    [desc].  It is an error to use more than one key with the same [name]. *)

val create_raw : doc:Doc.t -> stage:stage -> default:'a -> string -> 'a Desc.t -> 'a key

val set : 'a key -> 'a -> unit
(** Allow to set the value of a key. *)

type t = Any : 'a key -> t

val hide : 'a key -> t

val compare : t -> t -> int
(** [compare k1 k2] is [compare (name k1) (name k2)]. *)

module Set : sig
  include Set.S with type elt = t
  include Functoria_misc.Monoid with type t := t
  val filter_stage : stage:[< `Both | `Configure | `Run ] -> t -> t
end

val name : t -> string

val ocaml_name : t -> string
(** [name k] is just [ocamlify k.name].  Two keys [k1] and [k2] are considered
    equal if [name k1 = name k2]. *)

val pp_meta : t Fmt.t
(** [pp_meta fmt key] prints the code needed to get the value of a key. *)

val stage : t -> stage

val is_runtime : t -> bool
val is_configure : t -> bool


val term_key : t -> unit Cmdliner.Term.t
(** [term_key k] is a [Cmdliner.Term.t] that, when evaluated, sets the value
    of the the key [k]. *)

val term : ?stage:stage -> Set.t -> unit Cmdliner.Term.t
(** [term l] is a [Cmdliner.Term.t] that, when evaluated, sets the value of the
    the keys in [l]. *)

type 'a value

val with_deps : keys:Set.t -> 'a value -> 'a value
val pure : 'a -> 'a value
val value : 'a key -> 'a value
val app : ('a -> 'b) value -> 'a value -> 'b value
val ($) : ('a -> 'b) value -> 'a value -> 'b value
val map : ('a -> 'b) -> 'a value -> 'b value
val pipe : 'a value -> ('a -> 'b) -> 'b value
val if_ : bool value -> 'a -> 'a -> 'a value

val deps : 'a value -> Set.t

val peek : 'a value -> 'a option

val eval : 'a value -> 'a

val term_value : ?stage:stage -> 'a value -> 'a Cmdliner.Term.t

val serialize : Format.formatter -> t -> unit
(** [serialize () k] returns a string [s] such that if [k.v] is [V (_, r)],
    then evaluating the contents of [s] will produce the value [!r]. *)

val describe : Format.formatter -> t -> unit
(** [describe () k] returns a string [s] such that if [k.v] is [V (d, _)],
    then evaluating the contents of [s] will produce the value [d]. *)

val emit : Format.formatter -> t -> unit

val pp_deps : 'a value Fmt.t

(**/*)

val get : 'a key -> 'a

val module_name : string
