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

(** Abstract type of a netfront instance *)
type t

(** Abstract id to refer to a netfront instance *)
type id

(** Get a list of all the available Netfronts ids
  *)
val enumerate: unit -> id list Lwt.t

(** Create a netfront Ethernet interface
  * id -> netfront *)
val create: id -> t Lwt.t

(** Add a receive callback function to this netfront. *)
val set_recv : t -> (Hw_page.sub -> unit) -> unit

(** Transmit a packet; can block
  * netfront -> buffer -> offset -> length -> unit Lwt.t
  *)
val xmit: t -> string -> int -> int -> unit Lwt.t

(** Return an Ethernet MAC address for a netfront *)
val mac: t -> string
