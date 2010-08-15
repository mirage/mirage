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

type console = {
    backend_id: int;
    gnt: Gnttab.r;
    ring: Ring.Console.t;
    evtchn: int;
    waiters: unit Lwt.u Lwt_sequence.t;
}

exception Internal_error of string

let create () =
    let node = "device/console/0/" in
    lwt backend = Xs.t.Xs.read (node ^ "backend") in
    lwt backend_id = try return (int_of_string backend)
        with _ -> fail (Internal_error "backend id is not an integer") in
    lwt gnt, ring = Ring.Console.alloc backend_id in
    let evtchn = Evtchn.alloc_unbound_port backend_id in
    let waiters = Lwt_sequence.create () in
    Xs.transaction Xs.t (fun xst ->
        let wrfn k v = xst.Xst.write (node ^ k) v in
        wrfn "ring-ref" (Gnttab.to_string gnt) >> 
        wrfn "port" (string_of_int evtchn) >>
        wrfn "protocol" "x86_64-abi" >>
        wrfn "type" "ioemu" >> (* XXX whats this for? *)
        wrfn "state" (Xb.State.to_string Xb.State.Connected)
    ) >>
    return { backend_id=backend_id; gnt=gnt; ring=ring; 
        evtchn=evtchn; waiters=waiters }

