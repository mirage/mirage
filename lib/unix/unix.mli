(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

module Console : sig
  type t
  exception Internal_error of string
  val t : t
  val create : unit -> t
  val create_additional_console : unit -> t Lwt.t
  val sync_write : t -> string -> int -> int -> unit Lwt.t
  val write : t -> string -> int -> int -> unit
  val log : string -> unit
end

module Clock : sig
  val time : unit -> float
end

module Time : sig
  val sleep : float -> unit Lwt.t
end

module Ethif : sig
    type t
    type id
    val enumerate : unit -> id list Lwt.t
    val create : id -> t Lwt.t
    val destroy : t -> unit Lwt.t
    val input : t -> (Mpl.Ethernet.o -> unit Lwt.t) -> unit Lwt.t list
    val has_input: t -> bool
    val wait : t -> unit Lwt.t
    val output : t -> Mpl.Ethernet.x -> unit Lwt.t
    val mac : t -> string
end

module Main : sig
  val run : unit Lwt.t -> unit
end
