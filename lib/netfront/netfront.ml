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

module Req = struct
    type w

    type flags = RX_data_validated | RX_checksum_blank | RX_more_data | RX_extra_info
    type resp_raw = {
        id: int;
        offset: int;
        flags: int;
        status: int;
        data: string;
    }
    let resp_raw_to_string x = sprintf "{id=%d off=%d flags=%d status=%d}" x.id x.offset x.flags x.status

    (** wrap -> index -> req to retrieve pointer *)
    external rx_get : nw -> int -> w = "caml_nf_rx_req_get"
    external set_gnt : w -> Gnttab.r -> unit = "caml_nf_req_set_gnt"
    external set_id : w -> int -> unit = "caml_nf_req_set_id"
    external rx_prod_set : nw -> int -> int -> unit = "caml_nf_rx_req_prod_set"
    external rx_prod_get : nw -> int = "caml_nf_rx_req_prod_get"
    external recv : nw -> resp_raw = "caml_nf_receive"
    external recv_ack : nw -> bool = "caml_nf_receive_ack"
end

type netfront = {
    backend_id: int;
    backend: string;
    mac: string;
    tx_ring_ref: Gnttab.r;
    rx_ring_ref: Gnttab.r;
    evtchn: int;
    cb: unit -> unit;
    rx_slots: (int * Gnttab.r * Req.w) array;
    state: nw;
}

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
    print_endline "init_rx_buffers";
    let rec get_rx_slots num acc =
        match num with
        | 0 -> return acc
        | num -> 
            let id = num - 1 in
            lwt gnt = Gnttab.get_free_entry () in
            let slot = Req.rx_get state id in
            Req.set_gnt slot gnt;
            Req.set_id slot id;
            Gnttab.grant_access gnt domid Gnttab.RW;
            get_rx_slots id ((id,gnt,slot) :: acc)
    in 
    lwt rx_slots = get_rx_slots (rx_ring_size state) [] in
    let rx_slots = Array.of_list rx_slots in
    Req.rx_prod_set state evtchn (rx_ring_size state);
    print_endline "init_rx_buffers: done";
    let cb () =
      Printf.printf "netfront callback num=%d\n%!" num;
      let rec read () =
          (* Read the raw descriptor *)
          let resp_raw = Req.recv state in
          (* Lookup the grant page from the id in the raw descriptor *)
          let id',gnt,req = rx_slots.(resp_raw.Req.id) in
          printf "   %d = %d ?\n%!" resp_raw.Req.id id';
          printf "   raw= %s   gntid=%d\n%!" (Req.resp_raw_to_string resp_raw) (Gnttab.gnttab_ref gnt);
          (* Remove netback access to this grant *)
          Gnttab.end_access gnt;
          (* For now, just copy the grant over to an OCaml string.
             TODO: zero copy implementation *)
          let data = Gnttab.read gnt resp_raw.Req.offset resp_raw.Req.status in
          printf "    %s\n%!" (Mir.prettyprint data);
          (* since it has been copied, replenish the same used grant back to netfront *)
          Gnttab.grant_access gnt domid Gnttab.RW;
          Req.rx_prod_set state evtchn (Req.rx_prod_get state);
          if Req.recv_ack state then
              read ()
       in read ()
    in
    Lwt_mirage_main.Activations.register evtchn cb;
    Mmap.evtchn_unmask evtchn;

    return { backend_id=domid; tx_ring_ref=tx_ring_ref;
      rx_ring_ref=rx_ring_ref; evtchn=evtchn; state=state; rx_slots=rx_slots;
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
