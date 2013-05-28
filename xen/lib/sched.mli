(*
 * Copyright (c) Citrix Systems Inc
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

(** Xen scheduler operations. *)

(** Type of the argument of function [shutdown]. *)
type reason =
  | Poweroff
  | Reboot
  | Suspend
  | Crash

val add_resume_hook : (unit -> unit Lwt.t) -> unit
(** [add_resume_hook f] adds [f] in the list of functions to be called
    on resume. *)

val shutdown: reason -> unit
(** [shutdown reason] informs Xen that the unikernel has shutdown. The
    [reason] argument indicates the type of shutdown (according to
    this type and the configuration of the unikernel, Xen might
    restart the unikernel or not). To suspend, do a [shutdown Suspend]
    is not enough, use the function below instead. *)

val suspend: unit -> int Lwt.t
(** [suspend ()] suspends the unikernel and returns [0] after
    the kernel has been resumed, in case of success, or
    immediately returns a non-zero value in case of error. *)
