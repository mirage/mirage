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

(** Activations provides an interface to wait for a file descriptor
    to become available for either reading or writing *)

(** Wait for the file descriptor to become ready for reading 
    @param fd file descriptor 
    @return a thread that blocks until the [fd] is ready for reading *)
val read: 'a Socket.fd -> unit Lwt.t

(** Wait for the file descriptor to become ready for writing 
    @param fd file descriptor 
    @return a thread that blocks until the [fd] is ready for writing *)
val write: 'a Socket.fd -> unit Lwt.t

val wait : float -> unit
