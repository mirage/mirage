(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

(** Configuration library. *)
open Functoria_sigs

include CORE
  with module Key = Functoria_key

(** A project is a specialized DSL build for specific purposes,
    like the mirage DSL. *)
module type PROJECT = sig

  val prelude : string

  val name : string

  val version : string

  val driver_error : string -> string

  val configurable :
    name:string -> root:string -> job impl list ->
    job configurable

end

module type S = Functoria_sigs.S
  with module Key := Functoria_key
   and module Info := Info
   and type 'a impl = 'a impl
   and type 'a typ = 'a typ
   and type any_impl = any_impl
   and type job = job
   and type 'a configurable = 'a configurable

module type KEY = Functoria_sigs.KEY
  with type 'a key = 'a Key.key
   and type 'a value = 'a Key.value
   and type t = Key.t
   and type Set.t = Key.Set.t

(** Create a specialized configuration engine for a project. *)
module Make (Project : PROJECT) : sig

  include S

  val launch : unit -> unit
  (** Launch the cmdliner application.
      Should only be used by the host specialized DSL.
  *)

end
