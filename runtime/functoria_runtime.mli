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

(** [Arg] defines command-line arguments which can be set at runtime.
    This module is the runtime companion of {!Functoria_key}. It
    exposes a subset of
    {{:http://erratique.ch/software/cmdliner/doc/Cmdliner.Arg.html}
    Cmdliner.Arg}. *)
module Arg: sig

  (** {1 Runtime command-line arguments} *)

  type 'a t
  (** The type for runtime command-line arguments. Similar to
      {!Functoria_key.Arg.t} but only available at runtime. *)

  val opt: 'a Cmdliner.Arg.converter -> 'a -> Cmdliner.Arg.info -> 'a t
  (** [opt] is the runtime companion of {!Functoria_key.Arg.opt}. *)

  val required: 'a Cmdliner.Arg.converter -> Cmdliner.Arg.info -> 'a t
  (** [required] is the runtime companion of {!Functoria_key.Arg.required}. *)

  val key: ?default:'a -> 'a Cmdliner.Arg.converter -> Cmdliner.Arg.info -> 'a t
  (** [key] is either {!opt} or {!runtime}, depending if [~default] is provided. *)

  val flag: Cmdliner.Arg.info -> bool t
  (** [flag] is the runtime companion of {!Functoria_key.Arg.flag}. *)

end

(** [Key] defines values that can be set by runtime command-line
    arguments. This module is the runtime companion of
    {!Functoria_key}. *)
module Key: sig

  (** {1 Runtime keys} *)

  type 'a t
  (** The type for runtime keys containing a value of type ['a]. *)

  val create: 'a Arg.t -> 'a t
  (** [create conv] create a new runtime key. *)

  val get: 'a t -> 'a
  (** [get k] is the value of the key [k]. Use the default value if no
      command-line argument is provided.
      @raise Invalid_argument if called before cmdliner's evaluation.
  *)

  val default : 'a t -> 'a option
  (** [default k] is the default value of [k], if one is available.
      This function can be called before cmdliner's evaluation.
  *)

  val term: 'a t -> unit Cmdliner.Term.t
  (** [term k] is the [Cmdliner] term whose evaluation sets [k]s'
      value to the parsed command-line argument. *)

end

(** [with_argv keys name argv] evaluates the [keys] {{!Key.term}terms}
    on the command-line [argv]. [name] is the executable name. *)
val with_argv : unit Cmdliner.Term.t list -> string -> string array -> unit
