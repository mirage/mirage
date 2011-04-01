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

type r
type num = int32
type perm = RO | RW

val alloc: ?page:Istring.Raw.t -> num -> r
val num: r -> num
val page: r -> Istring.Raw.t
val put_free_entry : r -> unit
val get_free_entry : unit -> r Lwt.t
val get_n : domid:int -> perm:perm -> int -> r list Lwt.t
val grant_access : domid:int -> perm:perm -> r -> unit
val end_access : r -> unit
val to_string : r -> string
val detach : r -> Istring.Raw.t
val attach : r -> Istring.Raw.t -> unit

val with_grant : domid:int -> perm:perm -> (r -> 'a Lwt.t) -> 'a Lwt.t
val with_grants : domid:int -> perm:perm -> int -> (r array -> 'a Lwt.t) -> 'a Lwt.t
