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

val write : Fpath.t -> string array -> unit Action.t
(** [write f argv] writes the context cache in the file [f]. *)

val read : Fpath.t -> t option Action.t
(** [read f] reads the context cache stored in [f]. The result is
    [Action.ok None] if [f] does not exists and [Action.error _] if the cache
    contains garbage. *)

val eval : t option -> Key.context Cmdliner.Term.t -> Key.context Action.t
(** [eval_context t term] is the context obtained by evaluating [term] over the
    cached context [t]. The result is {!Key.empty_context} if the cache is not
    present (e.g. if [t = None]).. *)

val eval_output : t option -> string option Action.t
(** [eval_output t] is the evaluation of {!Cli.output} over the cached context
    [t]. *)

val require : t option -> t Cmdliner.Term.ret
(** [require t] is [x] iff [t = Some x] otherwise it is an error. *)
