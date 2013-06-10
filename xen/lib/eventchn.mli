(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2013 Citrix Inc
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

(** Event channel interface. *)

type handle
(** An initialised event channel interface. *)

type t
(** A local event channel. *)

val to_int: t -> int
(** [to_int evtchn] is the port number of [evtchn]. *)

val console_port: unit -> t
(** [console_port ()] is the pre-allocated console event channel *)

val xenstore_port : unit -> t
(** [xenstore_port ()] is the pre-allocated xenstore event channel *)

val init: unit -> handle
(** [init ()] is an initialised event channel interface. Will never
    throw an exception. *)

val notify : handle -> t -> unit
(** [notify h c] notifies the [t]. *)

val bind_interdomain : handle -> int -> int -> t
(** [bind_interdomain h domid remote_port] is a local event channel
    connected to domid:remote_port. On error it will return -1. *)

val bind_unbound_port : handle -> int -> t
(** [bind_unbound_port h remote_domid] is a new event channel awaiting
    an interdomain connection from [remote_domid]. On error it will
    return -1. *)

val bind_dom_exc_virq : handle -> t
(** [bind_dom_exc_virq h] binds a local event channel to the
    VIRQ_DOM_EXC (domain exception VIRQ). On error it will return
    -1. *)

val unbind : handle -> t -> unit
(** [unbind h c] unbinds [c]. *)

val unmask : handle -> t -> unit
(** [unmask h c] unmasks [c]. *)

val is_valid : t -> bool
(** [is_valid c] is true if [t] is bound. Bindings are invalidated
    after a domain resume. *)

