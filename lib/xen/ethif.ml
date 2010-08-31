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

type t = {
    backend_id: int;
    backend: string;
    mac: string;
    tx_ring: Ring.Netif_tx.t;
    tx_ring_ref: Gnttab.r;
    tx_slots: (int * Gnttab.r) array;
    tx_freelist: int Queue.t;
    tx_freelist_cond: unit Lwt_condition.t;
    rx_ring: Ring.Netif_rx.t;
    rx_ring_ref: Gnttab.r;
    rx_slots: (int * Gnttab.r * Ring.Netif_rx.req) array;
    mutable rx_cond: unit Lwt_condition.t;
    env_pool: string Lwt_pool.t;
    evtchn: int;
}

type id = (int * int)

(* Given a VIF ID and backend domid, construct a netfront record for it *)
let create (num,backend_id) =
    Printf.printf "Netfront.create: start num=%d domid=%d\n%!" num backend_id;

    (* Allocate a transmit and receive ring, and event channel for them *)
    lwt (tx_ring_ref, tx_ring) = Ring.Netif_tx.alloc backend_id in
    lwt (rx_ring_ref, rx_ring)  = Ring.Netif_rx.alloc backend_id in
    let evtchn = Evtchn.alloc_unbound_port backend_id in

    (* Read xenstore info and set state to Connected *)
    let node = Printf.sprintf "device/vif/%d/" num in
    lwt backend = Xs.(t.read (node ^ "backend")) in
    lwt mac = Xs.(t.read (node ^ "mac")) in
    lwt () = Xs.(transaction t (fun xst ->
        let wrfn k v = xst.Xst.write (node ^ k) v in
        wrfn "tx-ring-ref" (Gnttab.to_string tx_ring_ref) >>
        wrfn "rx-ring-ref" (Gnttab.to_string rx_ring_ref) >>
        wrfn "event-channel" (string_of_int evtchn) >>
        wrfn "request-rx-copy" "1" >>
        wrfn "state" Xb.State.(to_string Connected)
      )) in

    (* Helper function to iterate through the rings and return
       an array of grant slots *)
    let rec iter_n fn num acc =
        match num with
        | 0 -> return (Array.of_list acc)
        | num -> 
            lwt gnt = Gnttab.get_free_entry () in
            let id = num - 1 in
            lwt r = fn id gnt in
            iter_n fn id (r :: acc) in

    (* Push all the recv grants to the recv ring *)
    lwt rx_slots = Ring.Netif_rx.(iter_n 
        (fun id gnt ->
          let req = req_get rx_ring id in
          req_set req ~id ~gnt;
          Gnttab.grant_access gnt backend_id Gnttab.RW;
          return (id,gnt,req)
        ) size []
      ) in
    Ring.Netif_rx.req_push rx_ring Ring.Netif_rx.size evtchn;
    let rx_cond = Lwt_condition.create () in

    (* Record all the xmit grants in a freelist array, along
       with the indices in tx_freelist to look them up *)
    let tx_freelist = Queue.create () in
    let tx_freelist_cond = Lwt_condition.create () in
    lwt tx_slots = Ring.Netif_tx.(iter_n
      (fun id gnt ->
         Queue.push id tx_freelist;
         return (id,gnt)
      ) size []) in

    (* MPL string environment pool to use until zero copy *)
    let env_pool = Lwt_pool.create 5 
      (fun () -> return (String.make 4096 '\000')) in

    Activations.register evtchn (Activations.Event_condition rx_cond);
    Evtchn.unmask evtchn;

    return { backend_id; tx_ring; tx_ring_ref; rx_ring_ref; rx_ring; rx_cond;
      evtchn; rx_slots; tx_slots; mac; tx_freelist; tx_freelist_cond; 
      backend; env_pool }

(* Input all available pages from receive ring and return detached page list *)
let input_low nf =
    Ring.Netif_rx.(read_responses nf.rx_ring (fun pos res ->
      let id = res_get_id res in
      let offset = res_get_offset res in
      let status = res_get_status res in
      let id', gnt, req = nf.rx_slots.(id) in
      assert(id' = id);
      assert(id = pos); (* XXX this SHOULD fail when it overflows, just here to make sure it does and then remove *)
      Gnttab.end_access gnt;
      (* detach the data page from the grant and give it to the receive
      function to queue up for the application *)
      let sub = Gnttab.detach gnt offset status in
      (* Queue up the recv grant again *)
      req_set req ~id ~gnt;
      Gnttab.grant_access gnt nf.backend_id Gnttab.RW;
      req_push nf.rx_ring 1 nf.evtchn;
      (* Pass up the received page to the listener *)
      sub
    ))

(* Number of unconsumed responses waiting for receive *)
let has_input nf =
    Ring.Netif_rx.res_waiting nf.rx_ring > 0

(* Shutdown a netfront *)
let destroy nf =
    printf "netfront_destroy\n%!";
    return ()

(* Get a xmit grant slot from the free list *)
let rec get_tx_gnt nf =
    if Queue.is_empty nf.tx_freelist then (
      Lwt_condition.wait nf.tx_freelist_cond >> 
      get_tx_gnt nf)
    else
      let id = Queue.take nf.tx_freelist in
      let slot_id, gnt = nf.tx_slots.(id) in
      assert(slot_id = id);
      return (id, gnt)

(* Transmit a packet from buffer, with offset and length *)  
let output_raw nf sub =
    (* Grab a free grant slot from the free list, which may block *)
    lwt (id, gnt) = get_tx_gnt nf in
    (* Attach the incoming sub-page to the free grant *)
    Gnttab.attach sub gnt;
    (* Find our current request slot on the xmit queue *)
    let cur_slot = Ring.Netif_tx.req_get_prod nf.tx_ring in
    let req = Ring.Netif_tx.req_get nf.tx_ring cur_slot in
    (* Grant read accesss to the backend and setup the request *)
    let offset = sub.Hw_page.off in
    let size = sub.Hw_page.len in
    Gnttab.grant_access gnt nf.backend_id Gnttab.RO;
    Ring.Netif_tx.req_set_gnt req gnt;
    Ring.Netif_tx.req_set req ~offset ~flags:0 ~id ~size;
    Ring.Netif_tx.req_push nf.tx_ring 1 nf.evtchn;
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

(** Transmit an ethernet frame 
  * TODO Not yet zero copy, but it will be shortly, by Jove! *)
let output nf frame =
    Lwt_pool.use nf.env_pool (fun buf ->
      let env = Mpl.Mpl_stdlib.new_env buf in
      let sub = Hw_page.alloc_sub () in
      let _ = Mpl.Ethernet.m frame env in
      let buf = Mpl.Mpl_stdlib.string_of_env env in
      let len = String.length buf in
      Hw_page.write buf 0 sub.Hw_page.page 0 len;
      let sub = { sub with Hw_page.len=len } in
      output_raw nf sub
    )

(** Handle one frame
    TODO Not zero copy until the MPL backend is modified *)
let input nf fn =
   let subs = input_low nf in
   List.map (fun sub ->
     Lwt_pool.use nf.env_pool (fun buf ->
       let fillfn dstbuf dstoff len =
         Hw_page.(read sub.page sub.off dstbuf dstoff sub.len);
         Hw_page.(sub.len) in
       let env = Mpl.Mpl_stdlib.new_env ~fillfn buf in
       lwt () = fn (Mpl.Ethernet.unmarshal env) in
       return ()
     )
   ) subs

let wait nf = Lwt_condition.wait nf.rx_cond

(* The Xenstore MAC address is colon separated, very helpfully *)
let mac nf = 
  let s = String.create 6 in
  Scanf.sscanf nf.mac "%02x:%02x:%02x:%02x:%02x:%02x"
    (fun a b c d e f ->
      s.[0] <- Char.chr a;
      s.[1] <- Char.chr b;
      s.[2] <- Char.chr c;
      s.[3] <- Char.chr d;
      s.[4] <- Char.chr e;
      s.[5] <- Char.chr f;
    );
  s
