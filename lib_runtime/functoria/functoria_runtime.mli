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

(** Functoria runtime. *)

(** [Arg] defines command-line arguments which can be set at runtime. This
    module is the runtime companion of [Functoria.Key]. It exposes a subset of
    {{:http://erratique.ch/software/cmdliner/doc/Cmdliner/Arg/index.html}
      Cmdliner.Arg}. *)
module Arg : sig
  (** {1 Runtime command-line arguments} *)

  type 'a t
  (** The type for runtime command-line arguments. Similar to
      [Functoria.Key.Arg.t] but only available at runtime. *)

  val opt : 'a Cmdliner.Arg.conv -> 'a -> Cmdliner.Arg.info -> 'a t
  (** [opt] is the runtime companion of [Functoria.Ky.Arg.opt]. *)

  val opt_all :
    'a Cmdliner.Arg.conv -> 'a list -> Cmdliner.Arg.info -> 'a list t
  (** [opt_all] is the runtime companion of [Functoria.Key.Arg.opt_all]. *)

  val required : 'a Cmdliner.Arg.conv -> Cmdliner.Arg.info -> 'a t
  (** [required] is the runtime companion of [Functoria.Key.Arg.required]. *)

  val key : ?default:'a -> 'a Cmdliner.Arg.conv -> Cmdliner.Arg.info -> 'a t
  (** [key] is either {!opt} or {!required}, depending if [~default] is
      provided. *)

  val flag : Cmdliner.Arg.info -> bool t
  (** [flag] is the runtime companion of [Functoria.Key.Arg.flag]. *)
end

(** [Key] defines values that can be set by runtime command-line arguments. This
    module is the runtime companion of {!Key}. *)
module Key : sig
  (** {1 Runtime keys} *)

  type 'a t
  (** The type for runtime keys containing a value of type ['a]. *)

  val create : 'a Arg.t -> 'a t
  (** [create conv] create a new runtime key. *)

  val get : 'a t -> 'a
  (** [get k] is the value of the key [k]. Use the default value if no
      command-line argument is provided.

      @raise Invalid_argument if called before cmdliner's evaluation. *)

  val default : 'a t -> 'a option
  (** [default k] is the default value of [k], if one is available. This
      function can be called before cmdliner's evaluation. *)

  val term : 'a t -> unit Cmdliner.Term.t
  (** [term k] is the [Cmdliner] term whose evaluation sets [k]s' value to the
      parsed command-line argument. *)
end

val argument_error : int
(** [argument_error] is the exit code used for argument parsing errors: 64. *)

val with_argv : unit Cmdliner.Term.t list -> string -> string array -> unit
(** [with_argv keys name argv] evaluates the [keys] {{!Key.term} terms} on the
    command-line [argv]. [name] is the executable name. On evaluation error the
    application calls [exit(3)] with status [64]. If [`Help] or [`Version] were
    evaluated, [exit(3)] is called with status [63]. *)

type info = {
  name : string;
  libraries : (string * string) list;  (** the result of [dune-build-info] *)
}
(** The type for build information available at runtime. *)
