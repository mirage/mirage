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

type nw
external tx_ring_size : nw -> int = "caml_netfront_tx_ring_size"
external rx_ring_size : nw -> int = "caml_netfront_rx_ring_size"
(** backend domid -> tx gnttab -> rx gnttab -> state *)
external netfront_init: int -> Gnttab.r -> Gnttab.r -> nw = "caml_netfront_init"

module RX = struct
    type w

    type flags = RX_data_validated | RX_checksum_blank | RX_more_data | RX_extra_info
    type resp_raw = {
        id: int;
        offset: int;
        flags: int;
        status: int;
        data: string;
    }
    let resp_raw_to_string x = sprintf "{id=%d off=%d flags=%d status=%d}"
        x.id x.offset x.flags x.status

    (** wrap -> index -> req to retrieve pointer *)
    external rx_get : nw -> int -> w = "caml_nf_rx_req_get"
    external rx_set_gnt : w -> Gnttab.r -> unit = "caml_nf_rx_req_set_gnt"
    external rx_set_id : w -> int -> unit = "caml_nf_rx_req_set_id"
    external rx_prod_set : nw -> int -> int -> unit = "caml_nf_rx_req_prod_set"
    external rx_prod_get : nw -> int = "caml_nf_rx_req_prod_get"
    external recv : nw -> resp_raw = "caml_nf_receive"
    external recv_ack : nw -> bool = "caml_nf_receive_ack"
end

module TX = struct
    type w

    (** wrap -> index -> req to retrieve pointer *)
    external tx_get : nw -> int -> w = "caml_nf_tx_req_get"
    external tx_set_gnt : w -> Gnttab.r -> unit = "caml_nf_tx_req_set_gnt"
    external tx_set_param : w -> int -> int -> int -> int -> unit = "caml_nf_tx_req_set_param"
    external tx_prod_set : nw -> int -> int -> unit = "caml_nf_tx_req_prod_set"
    external tx_prod_get : nw -> int = "caml_nf_tx_req_prod_get"
end

type netfront = {
    backend_id: int;
    backend: string;
    mac: string;
    tx_ring_ref: Gnttab.r;
    rx_ring_ref: Gnttab.r;
    evtchn: int;
    rx_slots: (int * Gnttab.r * RX.w) array;
    tx_slots: (int * Gnttab.r * TX.w) array;
    tx_freelist: int Queue.t;
    tx_freelist_cond: unit Lwt_condition.t;
    state: nw;
}

type netfront_id = (int * int)

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let create xsh (num,domid) =
    Printf.printf "Netfront.create: start num=%d domid=%d\n%!" num domid;
    lwt tx_ring_ref = Gnttab.get_free_entry () in
    lwt rx_ring_ref = Gnttab.get_free_entry () in
    let state = netfront_init domid tx_ring_ref rx_ring_ref in
    Gnttab.grant_access tx_ring_ref domid Gnttab.RW;
    Gnttab.grant_access rx_ring_ref domid Gnttab.RW;
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
        let slot = RX.rx_get state id in
        RX.rx_set_gnt slot gnt;
        RX.rx_set_id slot id;
        Gnttab.grant_access gnt domid Gnttab.RW;
        return (id,gnt,slot)
      ) (rx_ring_size state) [] in
    RX.rx_prod_set state evtchn (rx_ring_size state);
    print_endline "init_tx_buffers";
    let tx_freelist = Queue.create () in
    let tx_freelist_cond = Lwt_condition.create () in
    lwt tx_slots = iter_n
      (fun num ->
         let id = num - 1 in
         lwt gnt = Gnttab.get_free_entry () in
         let slot = TX.tx_get state id in
         TX.tx_set_gnt slot gnt;
         Queue.push id tx_freelist;
         return (id,gnt,slot)
      ) (tx_ring_size state) [] in
    return { backend_id=domid; tx_ring_ref=tx_ring_ref;
      rx_ring_ref=rx_ring_ref; evtchn=evtchn; state=state;
      rx_slots=rx_slots; tx_slots=tx_slots; mac=mac; 
      tx_freelist=tx_freelist; tx_freelist_cond=tx_freelist_cond;
      backend=backend }

let set_recv nf callback  =
    Printf.printf "netfront recv: num=%d\n%!" nf.backend_id;
    let state = nf.state in
    let rec read () =
        (* Read the raw descriptor *)
        let resp_raw = RX.recv state in
        (* Lookup the grant page from the id in the raw descriptor *)
        let id',gnt,req = nf.rx_slots.(resp_raw.RX.id) in
        assert(id' = resp_raw.RX.id);
        printf "   raw= %s gntid=%d\n%!" 
        (RX.resp_raw_to_string resp_raw) (Gnttab.gnttab_ref gnt);
        (* Remove netback access to this grant *)
        Gnttab.end_access gnt;
        (* For now, just copy the grant over to an OCaml string.
           TODO: zero copy implementation *)
        let data = Gnttab.read gnt resp_raw.RX.offset resp_raw.RX.status in
        (* since it has been copied, replenish the same used grant back to netfront *)
        Gnttab.grant_access gnt nf.backend_id Gnttab.RW;
        (* advance the request producer pointer by one and push *)
        RX.rx_prod_set state nf.evtchn (RX.rx_prod_get state + 1);
        printf "    %s\n%!" (Mir.prettyprint data);
        let () = callback data in
        if RX.recv_ack state then read ()
    in 
    Lwt_mirage_main.Activations.register nf.evtchn read;
    Mmap.evtchn_unmask nf.evtchn

(* Transmit a packet from buffer, with offset and length *)  
let xmit nf buf off len =
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

(** Return a MAC address for a VIF *)
let mac nf = nf.mac
