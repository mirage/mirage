(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt

module FD = struct
  (* Low-level libev integration *)
  type mask = int (* bitmask: x&1 = read, x&2 = write *)
  type watcher (* abstract type created in bindings *)
  type fd = int
  external add : fd -> mask -> watcher = "caml_register_fd"
  external remove : watcher -> unit = "caml_unregister_fd"
  external callback : watcher -> (unit -> unit) -> unit = "caml_register_callback"

  let can_read (mask:mask) = mask land 1
  let can_write (mask:mask) = mask land 2

  let read_mask = 1
  let write_mask = 2
  
end

(* Register a read file descriptor and a one-shot callback function
   for when it is ready *)
let register_read fd cb =
  let watcher = FD.(add fd read_mask) in
  let cb' () = cb (); FD.remove watcher in
  FD.callback watcher cb'

(* Register a write file descriptor and a one-shot callback function
   for when it is ready *)
let register_write fd cb =
  let watcher = FD.(add fd write_mask) in
  let cb' () = cb (); FD.remove watcher in
  FD.callback watcher cb'
