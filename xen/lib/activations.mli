(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

(** Event channels handlers. *)

val wait : Eventchn.t -> unit Lwt.t
(** [wait evtchn] is a cancellable thread that will wake up when
    [evtchn] is notified. Cancel it if you are no longer interested in
    waiting on [evtchn]. *)

(** {2 Low level interface} *)

val run : Eventchn.handle -> unit
(** [run ()] goes through the event mask and activate any events,
    potentially spawning new threads. This function is called by
    [Main.run]. Do not call it unless you know what you are doing. *)

val resume : unit -> unit
(** [resume] needs to be called after the unikernel is
    resumed. However, this function is automatically called by
    {!Sched.suspend}. Do NOT use it unless you know what you are
    doing. *)
