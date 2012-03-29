(* -*- Mode: Caml; indent-tabs-mode: nil -*- *)
(******************************************************************************)
(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Interface Lwt_mon
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

let return_unit = Lwt.return ()

type 'a t = {
  mutable contents : 'a option;
  (* Current contents *)

  mutable writers : ('a * unit Lwt.u) Lwt_sequence.t;
  (* Threads waiting to put a value *)

  mutable readers : 'a Lwt.u Lwt_sequence.t;
  (* Threads waiting for a value *)
}

let create_empty () =
  { contents = None;
    writers = Lwt_sequence.create ();
    readers = Lwt_sequence.create () }

let create v =
  { contents = Some v;
    writers = Lwt_sequence.create ();
    readers = Lwt_sequence.create () }

let put mvar v =
  match mvar.contents with
    | None ->
        begin match Lwt_sequence.take_opt_l mvar.readers with
          | None ->
              mvar.contents <- Some v
          | Some w ->
              Lwt.wakeup_later w v
        end;
        return_unit
    | Some _ ->
        let (res, w) = Lwt.task () in
        let node = Lwt_sequence.add_r (v, w) mvar.writers in
        Lwt.on_cancel res (fun _ -> Lwt_sequence.remove node);
        res

let take mvar =
  match mvar.contents with
    | Some v ->
        begin match Lwt_sequence.take_opt_l mvar.writers with
          | Some(v', w) ->
              mvar.contents <- Some v';
              Lwt.wakeup_later w ()
          | None ->
              mvar.contents <- None
        end;
        Lwt.return v
    | None ->
        let (res, w) = Lwt.task () in
        let node = Lwt_sequence.add_r w mvar.readers in
        Lwt.on_cancel res (fun _ -> Lwt_sequence.remove node);
        res
