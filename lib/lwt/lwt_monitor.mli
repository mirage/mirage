(* -*- Mode: Caml; indent-tabs-mode: nil -*- *)
(******************************************************************************)
(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_monitor
 ******************************************************************************
 * Copyright (c) 2009, Metaweb Technologies, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following
 * disclaimer in the documentation and/or other materials provided
 * with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY METAWEB TECHNOLOGIES ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL METAWEB TECHNOLOGIES BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************)

(** Monitors *)

(** Monitors implement a combined lock for synchronization with
    conditional variables for notification. *)

type t
    (** The monitor type, used to synchronize the activity of threads
        around a common shared resource or critical section of code. *)

type 'a condition
    (** Condition variable type. The type parameter denotes the type of
        value propagated from notifier to waiter. *)

val create_condition : unit -> 'a condition
    (** [create_condition ()] creates a new condition variable. *)

val create : unit -> t
    (** [create ()] creates a new monitor. *)

val lock : t -> unit Lwt.t
    (** [lock mon] locks a monitor to gain exclusive access to a
        shared resource. If the monitor is currently locked by another
        thread, the thread calling [lock] will block until the monitor
        is unlocked.  Note that a monitor must not be "re-entered",
        i.e. [lock] called more than once without an intervening
        [unlock] call. *)

val unlock : t -> unit
    (** [unlock mon] unlocks a monitor. This releases exclusive access
        to a shared resource and allows other threads to enter the
        monitor. *)

val with_lock : t -> (unit -> 'a Lwt.t) -> 'a Lwt.t
    (** [with_lock mon f] is used to lock a monitor within a block scope.
        The function [f ()] is called with the monitor locked, and its
        result is returned from the call to [with_lock]. If an exception
        is raised from f, the monitor is also unlocked before the scope of
        [with_lock] is exited. *)

val wait : t -> 'a condition -> 'a Lwt.t
    (** [wait mon condvar] will cause the current thread to block,
        awaiting notification for a condition variable, condvar. The
        calling thread be within the monitor (must have previously
        called [lock] or be within the scope of [with_lock]). The
        monitor is temporarily unlocked until the condition is
        notified. Upon notification, the monitor is re-locked before
        [wait] returns and the thread's activity is resumed. When the
        awaited condition is notified, the value parameter passed to
        [notify] is returned. *)

val notify : t -> 'a condition -> 'a -> unit
    (** [notify mon condvar value] notifies that a condition is
        ready. A single waiting thread will be awoken and will receive
        the notification value which will be returned from [wait]. The
        calling thread be within the monitor (must have previously
        called [lock] or be within the scope of [with_lock]). Note
        that condition notification is not "sticky", i.e. if there is
        no waiter when [notify] is called, the notification will be
        missed and the value discarded. *)

val notify_all : t -> 'a condition -> 'a -> unit
    (** [notify_all mon condvar value] notifies all waiting
        threads. Each will be awoken in turn and will receive the same
        notification value. The calling thread be within the monitor
        (must have previously called [lock] or be within the scope of
        [with_lock]). *)
