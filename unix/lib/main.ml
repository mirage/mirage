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

let exit_hooks = Lwt_sequence.create ()
let enter_hooks = Lwt_sequence.create ()

let rec call_hooks hooks  =
  match Lwt_sequence.take_opt_l hooks with
    | None ->
        return ()
    | Some f ->
        (* Run the hooks in parallel *)
        let _ =
          try_lwt
            f ()
          with exn ->
            Printf.printf "enter_t: exn %s\n%!" (Printexc.to_string exn);
            return ()
        in
        call_hooks hooks

open Printf

(* Main runloop, which registers a callback so it can be invoked
   when timeouts expire. Thus, the program may only call this function
   once and once only. *)
let run t =
  Printexc.record_backtrace true;
  let t = call_hooks enter_hooks <&> t in
  let rec fn () =
    Gc.compact ();
    (* Wake up any paused threads, and restart threads waiting on timeout *)
    Lwt.wakeup_paused ();
    Time.restart_threads Clock.time;
    (* Attempt to advance the main loop thread *)
    match Lwt.poll t with
    | Some x ->
       (* The main thread has completed, so return the value *)
       x
    | None -> 
       (* If we have nothing to do, then check for the next
          timeout and block the domain *)
       let timeout =
         match Time.select_next Clock.time with
         |None -> 86400.0
         |Some tm -> tm
       in
       Activations.wait timeout;
       fn ()
  in
  fn ()

let () = at_exit (fun () -> run (call_hooks exit_hooks))
let at_exit f = ignore (Lwt_sequence.add_l f exit_hooks)
let at_enter f = ignore (Lwt_sequence.add_l f enter_hooks)
