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

(** Create network interface values from UNIX interfaces *)

(** This module handles the creation and destruction of network
    interface values usable in Mirage from real UNIX interfaces. If
    Mirage has to use a given network interface, the latter has to be
    created with mirari or standard UNIX tool, and advertised to this
    module using the [add_vif] function. This is analogous to the
    XenStore mechanism for the Xen backend. *)

(** Type representing a network interface, containing low level data
    structures to read and write from it. *)
type t

(** Textual id identifying a network interface, e.g. "tap0". *)
type id = string

(** Type of network interfaces. Currently, [ETH] designate a TUN/TAP
    interface, while [PCAP] designate a normal ethernet interface to
    attach to. *)
type dev_type =
| PCAP
| ETH

(** Type of callbacks that will be called on each created
    interface. *)
type callback = id -> t -> unit Lwt.t

(** Exception raised when trying to read from a DOWN interface *)
exception Device_down of id

(** Accessors for the t type *)

val get_writebuf : t -> Cstruct.t Lwt.t
val mac          : t -> string
val ethid        : t -> id

(** [add_vif id kind fd] adds a network interface to the XenStore
    analog of the UNIX backend. All interfaces that the unikernel
    should handle MUST be added with [add_vif] BEFORE using
    [create]. *)
val add_vif : id ->  dev_type -> Unix.file_descr -> unit

(** [create callback] is a thread that listens to the XenStore analog
    and creates a value of type t for each interface added with
    [add_vif], then call [callback] on it. *)
val create : callback -> unit Lwt.t

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

