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

type netfront_state

type netfront = {
    backend_id: int;
    backend: string;
    mac: string;
    tx_ring_ref: Gnttab.r;
    rx_ring_ref: Gnttab.r;
    evtchn: int;
    cb: unit -> unit;
    state: netfront_state;
}

(** backend domid -> tx gnttab -> rx gnttab -> state *)
external netfront_init: int -> Gnttab.r -> Gnttab.r 
   -> netfront_state = "caml_netfront_init"

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let create xsh (num,domid) =
    Printf.printf "Netfront.create: start num=%d domid=%d\n%!" num domid;
    lwt tx_ring_ref = Gnttab.get_free_entry () in
    lwt rx_ring_ref = Gnttab.get_free_entry () in
    let state = netfront_init domid tx_ring_ref rx_ring_ref in
    let evtchn = Mmap.evtchn_alloc_unbound_port domid in
    let node = Printf.sprintf "device/vif/%d/" num in
    lwt backend = xsh.Xs.read (node ^ "backend") in
    lwt mac = xsh.Xs.read (node ^ "mac") in
    lwt () = Xs.transaction xsh (fun xst ->
        let wrfn k v = xst.Xst.write (node ^ k) v in
        wrfn "tx-ring-ref" (Gnttab.to_string tx_ring_ref) >>
        wrfn "rx-ring-ref" (Gnttab.to_string rx_ring_ref) >>
        wrfn "event-channel" (string_of_int evtchn) >>
        wrfn "request-rx-copy" "1" >>
        wrfn "state" (Xb.State.to_string Xb.State.Connected)
    ) in
    let cb () = Printf.printf "netfront callback num=%d\n%!" num in
    Lwt_mirage_main.Activations.register evtchn cb;
    Mmap.evtchn_unmask evtchn;
    return { backend_id=domid; tx_ring_ref=tx_ring_ref;
      rx_ring_ref=rx_ring_ref; evtchn=evtchn; state=state;
      mac=mac; backend=backend; cb=cb }
   
(** Return a list of valid VIF IDs *)
let enumerate xsh =
    (* Find out how many VIFs we have *)
    let rec read_vif num acc =
       try_lwt
          lwt sid = xsh.Xs.read (sprintf "device/vif/%d/backend-id" num) in
          let domid = int_of_string sid in
          printf "found: num=%d backend-id=%d\n%!" num domid;
          read_vif (succ num) ((num,domid) :: acc)
        with
          Xb.Noent -> return (List.rev acc)
     in
     read_vif 0 []
