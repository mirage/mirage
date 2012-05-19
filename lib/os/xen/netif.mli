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

(** Xen Netfront interface for Ethernet I/O *)

(** Type of a single netfront interface *)
type t

(** Textual id which is unique per netfront interface *)
type id = string

(** Create a hotplug interface that will spawn a new thread
    per network interface.
    @param fn Callback function that is invoked for every new netfront interface.
    @return Blocking thread that will unplug all the attached interfaces if cancelled.
  *)
val create : (id -> t -> unit Lwt.t) -> unit Lwt.t

(** Manually plug in a new network interface. Normally automatically invoked via Xenstore
    watches by the create function *)
val plug: id -> t Lwt.t

(** Manually unplug a network interface. This makes an effort not to block, so
    the unplugging is not guaranteed *)
val unplug: id -> unit

(** Output a Bitstring vector to an interface *)
val output : t -> Io_page.t list -> unit Lwt.t

(** Listen endlesses on a Netfront, and invoke the callback function as frames are
    received. *)
val listen : t -> (Io_page.t -> unit Lwt.t) -> unit Lwt.t

(** Enumerate all the currently available Netfronts (which may or may not be attached) *)
val enumerate : unit -> id list Lwt.t

(** Return the MAC address of the Netfront *)
val ethid : t -> string
val mac : t -> string
