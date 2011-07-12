(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

(** Type-safe OCaml wrapper for single-page Xen I/O rings
    Every ring is a 4K page, with separate types for requests
    and responses. The size of the number of requests is cunningly
    set to a power of 2, so the producer/consumer ints can wrap
    safely without needing to mask them. *)

(* For every ring, we need to have bindings that define the type
   of a request and response, and accessor functions for those
   structs to set fields.
 *)

open Lwt
open Printf

(* Allocate a new grant entry and initialise a ring using it *)
let alloc domid =
  lwt gnt = Gnttab.get_free_entry () in
  let page = Gnttab.page gnt in
  let perm = Gnttab.RW in
  Gnttab.grant_access ~domid ~perm gnt;
  return (gnt, page)

(*
  struct sring {
    RING_IDX req_prod, req_event;
    RING_IDX rsp_prod, rsp_event;
    uint8_t  netfront_smartpoll_active;
    uint8_t  pad[47];
  };
*)

type sring = {
  buf: string;      (* Overall I/O buffer *)
  off: int;         (* Offset into I/O buffer (in bits, not bytes *)
  header_size: int; (* Header of shared ring variables, in bits *)
  idx_size: int;    (* Size in bits of an index slot *)
  nr_ents: int;     (* Number of index entries *)
  name: string;     (* For pretty printing only *)
}

let init (buf,off,len) ~idx_size ~name =
  assert (len = (4096 * 8));
  let header_size = 32+32+32+32+(48*8) in (* header bits size of struct sring *)
  (* Round down to the nearest power of 2, so we can mask indices easily *)
  let round_down_to_nearest_2 x =
    int_of_float (2. ** (floor ( (log (float x)) /. (log 2.)))) in
  (* Free space in shared ring after header is accounted for *)
  let free_bytes = 4096 - (header_size / 8) in
  let nr_ents = round_down_to_nearest_2 (free_bytes / idx_size) in
  (* We store idx_size in bits, for easier Bitstring offset calculations *)
  let idx_size = idx_size * 8 in
  let t = { name; buf; off; idx_size; nr_ents; header_size } in
  printf "Shared.init: %s off=%d idxsize=%d nr_ents=%d\n%!" name off idx_size nr_ents;
  (* initialise the *_event fields to 1, and the rest to 0 *)
  let src,_,_ = BITSTRING { 0l:32; 1l:32:littleendian; 0l:32; 1l:32:littleendian; 0L:64 } in
  String.blit src 0 buf (off/8) (String.length src);
  t

external sring_rsp_prod: sring -> int = "caml_sring_rsp_prod"
external sring_req_prod: sring -> int = "caml_sring_req_prod" 
external sring_req_event: sring -> int = "caml_sring_req_event"
external sring_rsp_event: sring -> int = "caml_sring_rsp_event"

external sring_push_requests: sring -> int -> unit = "caml_sring_push_requests"
external sring_push_responses: sring -> int -> unit = "caml_sring_push_responses" 

external sring_set_rsp_event: sring -> int -> unit = "caml_sring_set_rsp_event"
external sring_set_req_event: sring -> int -> unit = "caml_sring_set_req_event"

let nr_ents sring = sring.nr_ents

let slot sring idx =
  (* TODO should precalculate these and store in the sring? this is fast-path *)
  let idx = idx land (sring.nr_ents - 1) in
  let off = sring.off + sring.header_size + (idx * sring.idx_size) in
  (sring.buf, off, sring.idx_size)

module Front = struct

  type t = {
    mutable req_prod_pvt: int;
    mutable rsp_cons: int;
    sring: sring;
  }

  let init ~sring =
    let req_prod_pvt = 0 in
    let rsp_cons = 0 in
    { req_prod_pvt; rsp_cons; sring }

  let get_free_requests t =
    t.sring.nr_ents - (t.req_prod_pvt - t.rsp_cons)

  let is_ring_full t =
    get_free_requests t = 0

  let has_unconsumed_responses t =
    ((sring_rsp_prod t.sring) - t.rsp_cons) > 0

  let dump t =
    let sring = t.sring in
    printf "ring req_prod=%d req_event=%d rsp_prod=%d rsp_event=%d\n%!" (sring_req_prod sring)
     (sring_req_event sring) (sring_rsp_prod sring) (sring_rsp_event sring);
    Bitstring.hexdump_bitstring stdout (t.sring.buf,t.sring.off,128*8)

  let push_requests t =
    sring_push_requests t.sring t.req_prod_pvt

  let push_requests_and_check_notify t =
    let old_idx = sring_req_prod t.sring in
    let new_idx = t.req_prod_pvt in
    push_requests t;
    (new_idx - (sring_req_event t.sring)) < (new_idx - old_idx)

  let check_for_responses t =
    if has_unconsumed_responses t then
      true
    else begin
      sring_set_rsp_event t.sring (t.rsp_cons + 1);
      has_unconsumed_responses t
    end 

  let next_req_slot t =
    let s = slot t.sring t.req_prod_pvt in
    t.req_prod_pvt <- t.req_prod_pvt + 1;
    s

  (* consume outstanding responses and apply fn to the slots *)
  let rec ack_responses t fn =
    let rsp_prod = sring_rsp_prod t.sring in
    while t.rsp_cons != rsp_prod do
      printf "response: slot %d\n%!" t.rsp_cons;
      let () = fn (slot t.sring t.rsp_cons) in
      t.rsp_cons <- t.rsp_cons + 1;
    done;
    if check_for_responses t then ack_responses t fn
     
end

module Back = struct

  type t = {
    mutable rsp_prod_pvt: int;
    mutable req_cons: int;
    sring: sring;
  }

  let has_unconsumed_requests t =
    let req = (sring_req_prod t.sring) - t.req_cons in
    let rsp = t.sring.nr_ents - (t.req_cons - t.rsp_prod_pvt) in
    if req < rsp then (req > 0) else (rsp > 0)
 
  let push_responses t =
    sring_push_responses t.sring t.rsp_prod_pvt 

  let push_responses_and_check_notify t =
    let old_idx = sring_rsp_prod t.sring in
    let new_idx = t.rsp_prod_pvt in
    push_responses t;
    (new_idx - (sring_rsp_event t.sring)) < (new_idx - old_idx)

  let check_for_requests t =
    if has_unconsumed_requests t then
      true
    else begin
      sring_set_req_event t.sring (t.req_cons + 1);
      has_unconsumed_requests t
    end
end

(*
(* Module type of any request/response ring *)
module type RING = sig
  type req                              (* Request *)
  type res                              (* Response *)

  val alloc: int -> (Gnttab.r * Front.t) Lwt.t (* Allocate a ring *)
  val pending_responses: fring -> int   (* Pending responses *)
  val free_requests: fring -> int       (* Available req slots *)
  val max_requests: fring -> int        (* Max req slots *)

  val write: fring -> req list -> bool  (* Write requests to ring *)
  val read: fring -> res list           (* Read responses from ring *)
  val id_of_res: res -> int             (* Get id number in response *)
end
*)
(*
(* A bounded queue model that will block after a max
   number of requests. There are a fixed number of slots
   available, each with a grant id associated with it.
   A push to a ring will 'use up' an id, and a wakener
   will be called with the response when it's done. *)
module Bounded_ring (Ring:RING) = struct

  type id = int

  type t = {
    fring: Ring.fring;
    free_list: id Queue.t;
    push_waiters: unit Lwt.u Lwt_sequence.t;
    response_waiters: Ring.res Lwt.u option array;
  }

  let t ~backend_domid = 
    lwt gnt, fring = Ring.alloc backend_domid in
    let max_reqs = Ring.max_requests fring in
    Printf.printf "max_reqs=%d\n%!" max_reqs;
    let free_list = Queue.create () in
    (* Freelist queue of ids *)
    for id = 0 to max_reqs-1 do
      Queue.push id free_list
    done;
    let push_waiters = Lwt_sequence.create () in
    let response_waiters = Array.create max_reqs None in
    let r =  { fring; free_list; push_waiters; response_waiters } in
    return (gnt, r)

  let rec push t ~evtchn reqfns =
    let free_reqs = Queue.length t.free_list in
    let num_reqs = List.length reqfns in
    if num_reqs < 1 then
      return ()
    else begin
      if free_reqs >= num_reqs then begin
        (* Get a list of threads and wakeners for them *)
        let reqs, res_t = List.split (List.map (fun reqfn ->
          let id = Queue.pop t.free_list in
          let req, resfn = reqfn id in
          let th, u = Lwt.task () in
          let res_t =
            lwt res = th in 
            resfn res in
          t.response_waiters.(id) <- Some u;
          req, res_t
        ) reqfns) in
        (* Write to ring and notify if needed *)
        if Ring.write t.fring reqs then
          Evtchn.notify evtchn;
        join res_t
      end else begin
        (* Too many requests, so wait for some slots to free up *)
        (* TODO: chunk the requests to fit whatever can go now *)
        let th, u = Lwt.task () in
        let node = Lwt_sequence.add_r u t.push_waiters in
        Lwt.on_cancel th (fun _ -> Lwt_sequence.remove node);
        th >>
        push t ~evtchn reqfns
      end
    end      

  let rec push_one t ~evtchn reqfn =
    let free_reqs = Queue.length t.free_list in
    if free_reqs > 0 then begin
      let th, u = Lwt.task () in
      let id = Queue.pop t.free_list in
      let req = reqfn id in
      t.response_waiters.(id) <- Some u;
      if Ring.write t.fring [req] then
        Evtchn.notify evtchn;
      th
    end else begin
      let th, u = Lwt.task () in
      let node = Lwt_sequence.add_r u t.push_waiters in
      Lwt.on_cancel th (fun _ -> Lwt_sequence.remove node);
      th >>
      push_one t ~evtchn reqfn
    end
      
  (* Check for any responses and activate wakeners as they come in *)
  let poll t =
    List.iter
      (fun res ->
        let id = Ring.id_of_res res in
        match t.response_waiters.(id) with
        |None -> ()
        |Some u ->
          t.response_waiters.(id) <- None;
          Queue.push id t.free_list;
          Lwt.wakeup u res
      ) (Ring.read t.fring);
    match Lwt_sequence.take_opt_l t.push_waiters with
    |None -> ()
    |Some u -> Lwt.wakeup u ()

  let pending_responses t = Ring.pending_responses t.fring
  let max_requests t = Ring.max_requests t.fring
  let free_requests t = Ring.free_requests t.fring
end
*)

(* Raw ring handling section *)

module Console = struct
    type t
    let initial_grant_num : Gnttab.num = 2l
    external start_page: unit -> t = "caml_console_start_page"
    external zero: t -> unit = "caml_console_ring_init"
    external unsafe_write: t -> string -> int -> int = "caml_console_ring_write"
    external unsafe_read: t -> string -> int -> int = "caml_console_ring_read"
    let alloc_initial () =
      let num = initial_grant_num in
      let page = start_page () in
      let gnt = Gnttab.alloc num in
      gnt, page
end

module Xenstore = struct
    type t
    let initial_grant_num : Gnttab.num = 1l
    external start_page: unit -> t = "caml_xenstore_start_page"
    external zero: t -> unit = "caml_xenstore_ring_init"
    external unsafe_write: t -> string -> int -> int = "caml_xenstore_ring_write"
    external unsafe_read: t -> string -> int -> int = "caml_xenstore_ring_read"
    let alloc_initial () =
      let num = initial_grant_num in
      let page = start_page () in
      zero page;
      let gnt = Gnttab.alloc num in
      gnt, page
end

