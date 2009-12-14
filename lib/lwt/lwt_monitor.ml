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
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
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

open Lwt

module Condition =
struct
  type 'a t = 'a Lwt.u Queue.t

  let wait cvar =
    let (thread, w) = Lwt.wait () in
    Queue.add w cvar;
    thread

  let notify cvar arg =
    try
      let thread = Queue.take cvar in
      wakeup thread arg
    with Queue.Empty -> ()

  let notify_all cvar arg =
    try
      while true do
        let thread = Queue.take cvar in
        wakeup thread arg
      done
    with Queue.Empty -> ()
end

type 'a condition = 'a Condition.t
type t = { mutable locked : bool; enter : unit Condition.t }

let create () = { locked = false; enter = Queue.create () }
let create_condition = Queue.create

let rec lock m =
  if m.locked then
    Condition.wait m.enter >> lock m
  else begin
    m.locked <- true;
    return ()
  end

let unlock m =
  if m.locked then begin
    m.locked <- false;
    Condition.notify m.enter ()
  end

let wait m cond =
  let t = Condition.wait cond in
  unlock m;
  lwt arg = t in
  lwt () = lock m in
  return arg

let notify m cond arg =
  if m.locked then
    Condition.notify cond arg
  else
    failwith "Lwt_monitor.notify: not locked"

let notify_all m cond arg =
  if m.locked then
    Condition.notify_all cond arg
  else
    failwith "Lwt_monitor.notify: not locked"

let with_lock m thunk =
  lwt () = lock m in
  try_lwt
    lwt rv = thunk () in
    unlock m;
    return rv
  with exn ->
    unlock m;
    fail exn
