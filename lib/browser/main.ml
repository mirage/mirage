(* Lightweight thread library for Objective Caml
 * http://www.ocsigen.org/lwt
 * Module Lwt_main
 * Copyright (C) 2009 Jérémie Dimino
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, with linking exceptions;
 * either version 2.1 of the License, or (at your option) any later
 * version. See COPYING file for details.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 *)

open Lwt

external block_domain : float -> unit = "evtchn_block_domain"

(* Main runloop, which registers a callback so it can be invoked
   when timeouts expire. Thus, the program may only call this function
   once and once only. *)
let run t =
  let fn () =
    (* We have just been woken up, so check for event activations *)
    Activations.run ();
    (* Wake up any paused threads, and restart threads waiting on timeout *)
    Lwt.wakeup_paused ();
    Time.restart_threads Clock.time;
    (* Attempt to advance the main loop thread *)
    match Lwt.poll t with
    | Some x -> x
    | None -> 
       (* If we have nothing to do, then check for the next
          timeout and block the domain *)
       let timeout = Time.select_next Clock.time in
       (* XXX: the 0.1 is very hackish ...
          XXX: need to find a better solution than active polling here
          XXX: doesn't the above Lwt.poll should avoid such kind of situation ? *)
       block_domain (match timeout with None -> 0.1 |Some x -> x)
  in
  (* Register a callback for the JS runtime to restart this function *)
  let _ = Callback.register "evtchn_run" fn in
  fn ()

let exit_hooks = Lwt_sequence.create ()

let rec call_hooks () =
  match Lwt_sequence.take_opt_l exit_hooks with
    | None ->
        return ()
    | Some f ->
        lwt () =
          try_lwt
            f ()
          with exn ->
            return ()
        in
        call_hooks ()

let () = at_exit (fun () -> run (call_hooks ()))
let at_exit f = ignore (Lwt_sequence.add_l f exit_hooks)
