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

type handle

type r
type h
type perm = RO | RW

val to_int32: r -> int32
val of_int32: int32 -> r
val to_string : r -> string

val put : r -> unit
val get : unit -> r Lwt.t
val get_n : int -> r list Lwt.t

val num_free_grants : unit -> int

val with_ref: (r -> 'a Lwt.t) -> 'a Lwt.t
val with_refs: int -> (r list -> 'a Lwt.t) -> 'a Lwt.t

val grant_access : domid:int -> perm:perm -> r -> Io_page.t -> unit
val end_access : r -> unit

val map_grant : domid:int -> perm:perm -> r -> Io_page.t -> h option
val unmap_grant : h -> bool

val with_grant : domid:int -> perm:perm -> r -> Io_page.t -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val with_grants : domid:int -> perm:perm -> r list -> Io_page.t list -> (unit -> 'a Lwt.t) -> 'a Lwt.t

val with_mapping : handle -> int -> int32 -> perm -> (Io_page.t -> 'a Lwt.t) -> 'a Lwt.t

val map_contiguous_grant_refs : handle -> int -> int32 list -> perm -> Io_page.t

val unmap : handle -> Io_page.t -> unit
