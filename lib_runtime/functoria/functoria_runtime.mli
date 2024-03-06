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

(** [Arg] defines values that can be set by runtime command-line arguments. This
    module is the runtime companion of {!Functoria.Runtime_argq}. *)
module Arg : sig
  (** {1 Command-line Arguments} *)

  type 'a t
  (** The type for runtime keys parsing values of type ['a]. *)

  val create : 'a Cmdliner.Term.t -> 'a t
  (** [create t] is the command-line argument built from the [Cmdliner] term
      [t]. *)

  val conv :
    (string -> ('a, [ `Msg of string ]) result) ->
    ('a -> string) ->
    'a Cmdliner.Arg.conv
end

val register : 'a Cmdliner.Term.t -> unit -> 'a
(** [key t] registers the Cmdliner term [k] as a runtime key and return a
    callback [f] that evaluates to [t]s' value passed on the command-line.

    [f] will raise [Invalid_argument] if called before cmdliner's evaluation. *)

val argument_error : int
(** [argument_error] is the exit code used for argument parsing errors: 64. *)

val with_argv : unit Cmdliner.Term.t list -> string -> string array -> unit
(** [with_argv keys name argv] evaluates the [keys] {{!Key.term} terms} on the
    command-line [argv]. [name] is the executable name. On evaluation error the
    application calls [exit(3)] with status [64]. If [`Help] or [`Version] were
    evaluated, [exit(3)] is called with status [63]. *)

val runtime_args : unit -> unit Cmdliner.Term.t list
