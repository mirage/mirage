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

(** Block.Manager handles the collection of active block interfaces, and
    calls hotplug threads as they appear to the system. Unlike the Xen
    backend, this is largely an interface placeholder on UNIX since we 
    do not explicitly attach block devices to processes here. However,
    in the future, it could use a capability system to grant access to
    portions of the filesystem only when they are explicitly plugged. *)

open Lwt
open Printf

(** Textual identifier of a block device (string) *)
type id = string

(** Block interfaces in the socket backend are just NOOPs since we
    call the socket layer to take care of this for us *)
type interface = unit

(** An interface consists of its state descriptor and a
    thread to manage it (e.g. poll on activity) *)
type interface_t = interface * unit Lwt.t

(** Manager instance that tracks all active block instances *)
type t = {
  listener: t -> interface -> id -> unit Lwt.t;
  listeners: (id, interface_t) Hashtbl.t;
}

let plug t id vbd =
  let th,_ = Lwt.task () in
  let interface_t = vbd, th in
  Hashtbl.add t.listeners id interface_t;
  t.listener t vbd id

(* Unplug a block interface and cancel all its threads. *)
let unplug t id =
  try
    let i, th = Hashtbl.find t.listeners id in
    Lwt.cancel th;
    Hashtbl.remove t.listeners id
  with Not_found -> ()

(* Enumerate block devices and manage the protocol threads.
   The listener becomes a new thread that is spawned when a 
   new interface shows up. *)
let create listener =
  printf "Block.Manager: create\n%!";
  let listeners = Hashtbl.create 1 in
  let t = { listener; listeners } in
  (* Invoke the listener once *)
  let os = plug t "" () in
  let th,_ = Lwt.task () in
  Lwt.on_cancel th (fun _ ->
    printf "Block.Manager: cancel\n%!";
    Hashtbl.iter (fun id _ -> unplug t id) listeners);
  th <?> os

