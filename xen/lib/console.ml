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
open Printf

module Gnttab = Gnt.Gnttab

type t = {
  backend_id: int;
  gnt: Gnt.gntref;
  ring: Cstruct.t;
  evtchn: Eventchn.t;
  waiters: unit Lwt.u Lwt_sequence.t;
}

exception Internal_error of string

(** Called by a console thread that wishes to sleep (or be cancelled) *)
let wait cons = Activations.wait cons.evtchn

external console_start_page: unit -> Io_page.t = "caml_console_start_page"

let h = Eventchn.init ()

let create () =
  let backend_id = 0 in
  let gnt = Gnt.console in
  let page = console_start_page () in
  let ring = Io_page.to_cstruct page in
  Console_ring.Ring.init ring; (* explicitly zero the ring *)
  let evtchn = Eventchn.of_int Start_info.((get ()).console_evtchn) in
  let waiters = Lwt_sequence.create () in
  let cons = { backend_id; gnt; ring; evtchn; waiters } in
  Eventchn.unmask h evtchn;
  Eventchn.notify h evtchn;
  cons

let rec write_all cons buf off len =
  if len > String.length buf - off
  then Lwt.fail (Invalid_argument "len")
  else
    let w = Console_ring.Ring.Front.unsafe_write cons.ring buf off len in
    Eventchn.notify h cons.evtchn;
    let left = len - w in
    if left = 0 then return len
    else wait cons >> write_all cons buf (off+w) left


let write cons buf off len =
  if len > String.length buf - off then raise (Invalid_argument "len");
  let nb_written = Console_ring.Ring.Front.unsafe_write cons.ring buf off len in
  Eventchn.notify h cons.evtchn; nb_written

let t = create ()

let log s =
  let s = s ^ "\r\n" in
  let (_:int) = write t s 0 (String.length s) in ()

let log_s s =
  let s = s ^ "\r\n" in
  write_all t s 0 (String.length s) >>= fun (_:int) -> Lwt.return ()
