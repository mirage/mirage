(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

(** {1 Types} *)

(** Type representing a network interface, containing low level data
    structures to read and write from it *)
type t

(** Textual id identifying a network interface, e.g. "tap0" *)
type id = string

(** {2 Exceptions} *)

(** Exception raised when trying to read from a DOWN interface *)
exception Device_down of id

(** {3 Values} *)

(** Accessors for the t type *)

val get_writebuf : t -> Cstruct.t Lwt.t
val mac          : t -> string
val ethid        : t -> id


(** [create ~dev callback] will do the following, according to the
    value of ~dev:

    * if ~dev = None, create a tap interface, create a value of type t
    out of it and apply [callback] to it

    * Otherwise, attach to the interface specified in dev, create a
    value of type t value out of it and apply [callback] to it

    In all cases, the created t value will be kept in a global Hashtbl.
*)
val create : ?dev:(string option) -> (id -> t -> unit Lwt.t) -> unit Lwt.t

(** [listen netif cb] listens on [netif] for incoming frames, and call
    [cb] on them. *)
val listen : t -> (Cstruct.t -> unit Lwt.t) -> unit Lwt.t

(** [destroy netif] will destroy the interface [netif], i.e. marking
    it as inactive, closing the underlying file descriptor, and
    removing the corresponding t value from the Hashtbl. *)
val destroy : t -> unit Lwt.t

(** [write netif frame] write [frame] in [netif] *)
val write : t -> Cstruct.t -> unit Lwt.t

(** [writev netif frames] write [frames] in [netif] *)
val writev : t -> Cstruct.t list -> unit Lwt.t

