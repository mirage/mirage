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

(** Utility module. *)

(** {2 Misc} *)

open Rresult

val err_cmdliner : ?usage:bool -> ('a, string) result -> 'a Cmdliner.Term.ret

module type Monoid = sig
  type t

  val empty : t
  val union : t -> t -> t
end

module Name : sig
  module Opam : sig
    type t

    val to_string : t -> string
  end

  val opamify : string -> Opam.t
  val ocamlify : string -> string
end

(** {2 Deferred messages} *)

val defer_message : string -> unit
(** [defer_message msg] queues [msg] instead of printing it directly. The
    configuration DSL is evaluated before the command line is parsed, so a
    message printed at evaluation time would show up for every sub-command. The
    caller decides which sub-commands flush the queue with
    {!flush_deferred_messages}. *)

val flush_deferred_messages : unit -> unit
(** [flush_deferred_messages ()] prints the messages queued by {!defer_message}
    on standard output, in queueing order, and empties the queue. *)
