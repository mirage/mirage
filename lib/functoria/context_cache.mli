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

(** Manage context caches, via the [--context-file <file>] command-line
    argument. *)

type t
(** The type for cache. *)

val file : name:string -> 'a Cli.args -> Fpath.t
(** [file ~name args] is the filename of the context cache for the tool [name].
*)

val empty : t
(** The empty cache. *)

val is_empty : t -> bool
(** [is_empty t] is empty iff [t] is {!empty}. *)

val write : Fpath.t -> string array -> unit Action.t
(** [write f argv] writes the context cache in the file [f]. *)

val read : Fpath.t -> t Action.t
(** [read f] reads the context cache stored in [f]. The result is
    [Action.ok empty] if [f] does not exists and [Action.error _] if the cache
    contains garbage. *)

val peek : t -> Context.t Cmdliner.Term.t -> Context.t option
(** [peek t term] is the context obtained by evaluating [term] over the cached
    context [t]. *)

val merge : t -> Context.t Cmdliner.Term.t -> Context.t Cmdliner.Term.t
(** [eval_context t term] is the context obtained by evaluating [term] over the
    cached context [t]. *)

val peek_output : t -> string option
(** [peek_output t] is the evaluation of {!Cli.output} over the cached context
    [t]. *)
