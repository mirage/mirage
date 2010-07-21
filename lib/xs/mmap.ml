(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

type mmap_interface

external xenstore_init: unit -> mmap_interface = "stub_xenstore_init"
external xenstore_evtchn_port: unit -> int = "stub_xenstore_evtchn_port"
external xenstore_evtchn_notify: unit -> unit = "stub_xenstore_evtchn_notify"

(* Blocking Xenstore reads that may be cancelled will register with
   this sequence using wait(), and will be removed from it if cancelled *)
let waiters = Lwt_sequence.create ()

(** Callback to go through the active waiting threads and wake them *)
let perform_actions () =
    Lwt_sequence.iter_node_l 
      (fun node ->
         Lwt_sequence.remove node;
         Lwt.wakeup (Lwt_sequence.get node) ();
      ) waiters

(** Called by a Xenstore thread that wishes to sleep (or be cancelled) *)
let wait () =
   let t,u = Lwt.task () in
   let node = Lwt_sequence.add_r u waiters in
   Lwt.on_cancel t (fun _ -> Lwt_sequence.remove node);
   t

(** Register the callback for the Xenstore event port *)
let _ = 
    let port = xenstore_evtchn_port () in
    Printf.printf "CONDITION: registering on port %d\n%!" port;
    Lwt_mirage_main.Activations.register port perform_actions
