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

(** Xen Netfront interface for Ethernet I/O. *)

type t
(** Type of a single netfront interface. *)

type id
(** Textual id which is unique per netfront interface. Typically "0",
    "1", ... *)

val id_of_string : string -> id
val string_of_id : id -> string

val create : unit -> t list Lwt.t
(** [create ()] is a thread that returns a list of initialized
    netfront interfaces, one per detected netfront. *)

val id : t -> id
(** [id nf] is the id of the netfront [nf]. *)

val backend_id : t -> id
(** [backend_id nf] is the domid of the netback connected to the
    netfront [nf]. *)

val write : t -> Cstruct.t -> unit Lwt.t
(** [write nf buf] outputs [buf] to netfront [nf]. *)

val writev : t -> Cstruct.t list -> unit Lwt.t
(** [writev nf bufs] output a list of buffers to netfront [nf] as a
    single packet. *)

val listen : t -> (Cstruct.t -> unit Lwt.t) -> unit Lwt.t
(** [listen nf cb] is a thread that listens endlesses on [nf], and
    invoke the callback function as frames are received. *)

val mac : t -> string
(** [mac nf] is the MAC address of [nf]. *)

val get_writebuf : t -> Cstruct.t Lwt.t

val resume : unit -> unit Lwt.t
(** [resume ()] is a thread that resumes all devices when a unikernel
    is resumed. You do not have to call this function manually as it
    is already added as a resume hook for the [Sched.suspend]
    function. *)

val add_resume_hook : t -> (t -> unit Lwt.t) -> unit
(** [add_resume_hook nf cb] adds [cb] as a resume hook for netfront
	  [nf] - called on resume before the service threads are
	  restarted. Can be used, for example, to send a gratuitous ARP. *)

