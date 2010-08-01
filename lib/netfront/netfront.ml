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

type netfront = {
    backend_id: int;
    backend: string;
    mac: string;
    tx_ring: Ring.Netif_tx.t;
    tx_ring_ref: Gnttab.r;
    tx_slots: (int * Gnttab.r * Ring.Netif_tx.req) array;
    tx_freelist: int Queue.t;
    tx_freelist_cond: unit Lwt_condition.t;
    rx_ring: Ring.Netif_rx.t;
    rx_ring_ref: Gnttab.r;
    rx_slots: (int * Gnttab.r * Ring.Netif_rx.req) array;
    evtchn: int;
}

type netfront_id = (int * int)

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let create (num,domid) =
    Printf.printf "Netfront.create: start num=%d domid=%d\n%!" num domid;
    lwt (tx_ring_ref, tx_ring) = Ring.Netif_tx.alloc domid in
    lwt (rx_ring_ref, rx_ring)  = Ring.Netif_rx.alloc domid in
    let evtchn = Mmap.evtchn_alloc_unbound_port domid in

    let node = Printf.sprintf "device/vif/%d/" num in
    lwt backend = Xs.t.Xs.read (node ^ "backend") in
    lwt mac = Xs.t.Xs.read (node ^ "mac") in

    lwt () = Xs.transaction Xs.t (fun xst ->
        let wrfn k v = xst.Xst.write (node ^ k) v in
        wrfn "tx-ring-ref" (Gnttab.to_string tx_ring_ref) >>
        wrfn "rx-ring-ref" (Gnttab.to_string rx_ring_ref) >>
        wrfn "event-channel" (string_of_int evtchn) >>
        wrfn "request-rx-copy" "1" >>
        wrfn "state" (Xb.State.to_string Xb.State.Connected)
    ) in

    let rec iter_n fn num acc =
        match num with
        | 0 -> return (Array.of_list acc)
        | num -> 
            lwt r = fn num in
            iter_n fn (num - 1) (r :: acc) in

    print_endline "init_rx_buffers";
    lwt rx_slots = iter_n 
      (fun num ->
        let id = num - 1 in
        lwt gnt = Gnttab.get_free_entry () in
        let req = Ring.Netif_rx.req_get rx_ring id in
        Ring.Netif_rx.req_set req ~id ~gnt;
        Gnttab.grant_access gnt domid Gnttab.RW;
        return (id,gnt,req)
      ) Ring.Netif_rx.size [] in
    Ring.Netif_rx.req_push rx_ring Ring.Netif_rx.size evtchn;

    print_endline "init_tx_buffers";
    let tx_freelist = Queue.create () in
    let tx_freelist_cond = Lwt_condition.create () in
    lwt tx_slots = iter_n
      (fun num ->
         let id = num - 1 in
         lwt gnt = Gnttab.get_free_entry () in
         let res = Ring.Netif_tx.req_get tx_ring id in
         Ring.Netif_tx.req_set_gnt res gnt;
         Queue.push id tx_freelist;
         return (id,gnt,res)
      ) Ring.Netif_tx.size [] in

    return { backend_id=domid; tx_ring=tx_ring; tx_ring_ref=tx_ring_ref;
      rx_ring_ref=rx_ring_ref; rx_ring=rx_ring; evtchn=evtchn;
      rx_slots=rx_slots; tx_slots=tx_slots; mac=mac; tx_freelist=tx_freelist; 
      tx_freelist_cond=tx_freelist_cond; backend=backend }

let set_recv nf callback =
    Printf.printf "netfront recv: num=%d\n%!" nf.backend_id;
    let read () =
        Ring.Netif_rx.read_responses nf.rx_ring
           (fun pos res ->
              let id = Ring.Netif_rx.res_get_id res in
              let offset = Ring.Netif_rx.res_get_offset res in
              let status = Ring.Netif_rx.res_get_status res in
              let id', gnt, req = nf.rx_slots.(id) in
              assert(id' = id);
              assert(id = pos);
              Gnttab.end_access gnt;
              let data = Gnttab.read gnt offset status in
              Ring.Netif_rx.req_set req ~id ~gnt;
              Gnttab.grant_access gnt nf.backend_id Gnttab.RW;
              Ring.Netif_rx.req_push nf.rx_ring 1 nf.evtchn;
              callback data
           )
    in
    Lwt_mirage_main.Activations.register nf.evtchn 
       (Lwt_mirage_main.Activations.Event_thread read);
    Mmap.evtchn_unmask nf.evtchn

(* Transmit a packet from buffer, with offset and length *)  
let xmit nf buf off len =
(*
    (* Get an ID from the freelist *)
    let rec get_id () = 
      try 
        return (Queue.take nf.tx_freelist)
      with Queue.Empty ->
        Lwt_condition.wait nf.tx_freelist_cond >>
        get_id () in
    lwt id = get_id () in
    let state = nf.state in
    let cur_slot = TX.tx_prod_get state in
    let slot_id, gnt, req = nf.tx_slots.(cur_slot) in
    assert(slot_id = cur_slot);
    Gnttab.write gnt buf off len;
    Gnttab.grant_access gnt nf.backend_id Gnttab.RO;
    TX.tx_set_param req 0 len 0 id;
    TX.tx_prod_set state nf.evtchn (slot_id+1);
    return ()  
*)
    return ()

(** Return a list of valid VIF IDs *)
let enumerate () =
    (* Find out how many VIFs we have *)
    let rec read_vif num acc =
       try_lwt
          lwt sid = Xs.t.Xs.read (sprintf "device/vif/%d/backend-id" num) in
          let domid = int_of_string sid in
          printf "found: num=%d backend-id=%d\n%!" num domid;
          read_vif (succ num) ((num,domid) :: acc)
        with
          Xb.Noent -> return (List.rev acc)
     in
     read_vif 0 []

(** Return a MAC address for a VIF *)
let mac nf = nf.mac
