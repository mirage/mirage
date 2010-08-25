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
end

module Clock : sig
  val time : unit -> float
end

module Time : sig
  val sleep : float -> unit Lwt.t
end

module Hw_page : sig
  type t

  external blit : t -> int -> string -> int -> int -> unit = "caml_page_read_to_string"
  external get: t -> int -> char = "caml_page_safe_get" "noalloc"
  external get_byte: t -> int -> int = "caml_page_safe_get" "noalloc"
  external set: t -> int -> char -> unit = "caml_page_safe_set" "noalloc"
  external set_byte: t -> int -> int -> unit = "caml_page_safe_set" "noalloc"

  type sub = { off : int; len : int; page : t; }
  val alloc_sub: unit -> sub

  type extents
  val make : unit -> extents
  val push : sub -> extents -> unit
  val pop : extents -> sub
  val is_empty : extents -> bool
end

module Netfront : sig
  module Ethif : sig
    type t
    type id
    type data = Hw_page.sub
    val enumerate : unit -> id list Lwt.t
    val create : id -> t Lwt.t
    val input : t -> data list
    val wait_on_input : t -> unit Lwt.t
    val output : t -> data -> unit Lwt.t
    val alloc : t -> data
    val mac : t -> string
  end
end
