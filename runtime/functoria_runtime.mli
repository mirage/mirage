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

(** Functoria runtime. *)

(** [Converter] defines [Cmdliner]-compatible argument converters. This is the runtime companion of {!Functoria.Dsl.Key.t}*)
module Conv : sig

  (** {1 Argument Converters} *)

  type 'a t
  (** The type for argument converters. It is a wrapper around
      {!Cmdliner.Arg.converter}. *)

  val flag: bool t
  (** [flag] is a converter for an optional flag. The argument holds
      true if the flag is present on the command line and false
      otherwise. *)

  val opt: 'a Cmdliner.Arg.converter -> 'a t
  (** [opt a] wrap a {!Cmdliner.Arg.converter} into a converter for
      optional arguments. *)

  val int: int t
  (** [int] is an integer converter for optional arguments. *)

  val bool: bool t
  (** [bool] is a boolean converter for optional arguments. *)

  val string: string t
  (** [string] is a string converter for an optional argument. *)

end

(** [Key] allows keys to be set at runtime. *)
module Key : sig

  (** {1 Runtime keys} *)

  type 'a t
  (** The type for runtime keys containing a value of type ['a]. *)

  val create: doc:Cmdliner.Arg.info -> default:'a -> 'a Conv.t -> 'a t
  (** [create ~doc ~default conv] create a new key. *)

  val get: 'a t -> 'a
  (** [get k] is the value of the key [k]. Use the default value if no
      command-line argument is provided. *)

  val term: 'a t -> unit Cmdliner.Term.t
  (** [term k] is the [Cmdliner] term which, once evaluated, set the
      value of the runtime key. *)

end

(** [with_argv keys name argv] evaluates the [keys] {{!Key.term}terms}
    on the command-line [argv]. [name] is the executable name. *)
val with_argv : unit Cmdliner.Term.t list -> string -> string array ->
  [> `Error of string | `Ok of unit ]
