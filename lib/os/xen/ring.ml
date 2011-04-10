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
let alloc fn domid =
  lwt gnt = Gnttab.get_free_entry () in
  let page = Gnttab.page gnt in
  let ring = fn page in
  let perm = Gnttab.RW in
  Gnttab.grant_access ~domid ~perm gnt;
  return (gnt, ring)

(* Module type of any request/response ring *)
module type RING = sig
  type req                              (* Request *)
  type res                              (* Response *)
  type fring                            (* Front end ring *)

  val alloc: int -> (Gnttab.r * fring) Lwt.t (* Allocate a ring *)
  val pending_responses: fring -> int   (* Pending responses *)
  val free_requests: fring -> int       (* Available req slots *)
  val max_requests: fring -> int        (* Max req slots *)

  val write: fring -> req list -> bool  (* Write requests to ring *)

  val read: fring -> res list           (* Read responses from ring *)
  val id_of_res: res -> int             (* Get id number in response *)
end

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
        ();
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

module Netif = struct

  module Rx = struct

    module Req =  struct
      type t = {                (* request type *)
        id: int;
        gref: int32;
      }
    end

    module Res = struct
      (* id, off, flags, status *)
      type raw = (int * int * int * int)

      type flags = {
        checksum_blank: bool;
        data_validated: bool;
        more_data: bool;
        extra_info: bool;
      }

      type status =
      |Size of int
      |Err of int

      type t = {
        id: int;
        off: int;
        flags: flags;
        status: status;
      }

      let t_of_raw (id, off, fbits, code) =
        let flags = {
          checksum_blank = (fbits land 0b1 > 0);
          data_validated = (fbits land 0b10 > 0);
          more_data = (fbits land 0b100 > 0);
          extra_info = (fbits land 0b1000 > 0);
        } in
        let status = if code < 0 then Err code else Size code in
        {id; off; flags; status}
    end

    type id = int
    type req = Req.t
    type res = Res.t

    type sring = Istring.Raw.t  (* shared ring *)
    type fring                  (* front end ring *)

    module External = struct
      (* Initialise the shared ring and return a front ring *)
      external init: sring -> fring = "caml_netif_rx_init"
      (* Push a list of requests, bool return indicates notify needed *)
      external write: fring -> Req.t list -> bool = "caml_netif_rx_request"
      (* Read a list of responses to the request *)
      external read: fring -> Res.raw list = "caml_netif_rx_response"
      (* Number of responses pending *)
      external pending_responses: fring -> int = "caml_netif_rx_pending_responses"
      (* Maximum number of requests *)
      external max_requests: fring -> int = "caml_netif_rx_max_requests"
      (* Number of free requests *)
      external free_requests: fring -> int = "caml_netif_rx_free_requests"
    end

    let alloc = alloc External.init
    let id_of_res res = res.Res.id
    let read fring = List.map Res.t_of_raw (External.read fring) 
    let write = External.write
    let pending_responses = External.pending_responses
    let max_requests = External.max_requests
    let free_requests = External.free_requests

  end

  module Rx_t = Bounded_ring(Rx)

  module Tx = struct

    module Req = struct
      type gso_type = GSO_none | GSO_TCPv4
      type gso = { gso_size: int; gso_type: gso_type; gso_features: int }
      type extra = 
      |GSO of gso
      |Mcast_add of string (* [6] *)
      |Mcast_del of string (* [6] *)

      (* TODO: NETTXF_*: flags as a variant *)
      type flags = int

      type normal = {
        gref: int32;
        offset: int;
        flags: flags;
        id: int;
        size: int;
      }

      type t =
      |Normal of normal
      |Extra of extra
    end 

    module Res = struct
      type status = 
      |Dropped
      |Error
      |OK
      |Null

      (* id * status_code *)
      type raw = int * int 

      type t = {
        id: int;
        status: status;
      }

      let status_of_code = function
      |(-2) -> Dropped
      |(-1) -> Error
      |0 -> OK
      |_ -> Null

      let t_of_raw (id, code) =
        let status = status_of_code code in
        { id; status }
    end

    type id = int
    type req = Req.t
    type res = Res.t

    type sring = Istring.Raw.t
    type fring 

    module External = struct
      external init: sring -> fring = "caml_netif_tx_init"
      external write: fring -> Req.t list -> bool = "caml_netif_tx_request"
      external read: fring -> Res.raw list = "caml_netif_tx_response"
      external pending_responses: fring -> int = "caml_netif_tx_pending_responses"
      external max_requests: fring -> int = "caml_netif_tx_max_requests"
      external free_requests: fring -> int = "caml_netif_tx_free_requests"
    end

    let alloc = alloc External.init
    let id_of_res res = res.Res.id
    let read fring = List.map Res.t_of_raw (External.read fring) 
    let pending_responses = External.pending_responses
    let write = External.write
    let max_requests = External.max_requests
    let free_requests = External.free_requests
  end

  module Tx_t = Bounded_ring(Tx)
end

module Blkif = struct

  type vdev = int

  module Req = struct
    type op =
      |Read |Write |Write_barrier |Flush

    type seg = {
      gref: int32;
      first_sector: int;
      last_sector: int;
    }

    type t = {
      op: op;
      handle: vdev;
      id: int;
      sector: int64;
      segs: seg array;
    }
  end

  module Res = struct
    type status =
      |OK |Error |Not_supported |Unknown of int

    (* id * op * BLKIF_RSP *)
    type raw = (int * Req.op * int)

    type t = {
      id: int;
      op: Req.op;
      status: status;
    }

    let t_of_raw (id, op, rsp) =
      let status = match rsp with
      |0 -> OK
      |(-1) -> Error
      |(-2) -> Not_supported
      |x -> Unknown x in
      { id; op; status }
  end

  type id = int
  type req = Req.t
  type res = Res.t

  type sring = Istring.Raw.t
  type fring 

  module External = struct
    external init: sring -> fring = "caml_blkif_init"
    external write: fring -> Req.t list -> bool = "caml_blkif_request"
    external read: fring -> Res.raw list = "caml_blkif_response"
    external pending_responses: fring -> int = "caml_blkif_pending_responses"
    external max_requests: fring -> int = "caml_blkif_max_requests"
    external free_requests: fring -> int = "caml_blkif_free_requests"
  end

  let alloc = alloc External.init
  let id_of_res res = res.Res.id
  let read fring = List.map Res.t_of_raw (External.read fring) 
  let write = External.write
  let pending_responses = External.pending_responses
  let max_requests = External.max_requests
  let free_requests = External.free_requests
end

module Blkif_t = Bounded_ring(Blkif)

(* Raw ring handling section *)

(* Allocate a new grant entry for a raw ring *)
let alloc_raw zero domid =
  lwt gnt = Gnttab.get_free_entry () in
  let page = Gnttab.page gnt in
  zero page;
  let perm = Gnttab.RW in
  Gnttab.grant_access ~domid ~perm gnt;
  return (gnt, page)

module Console = struct
    type t = Istring.Raw.t
    let initial_grant_num : Gnttab.num = 2l
    external start_page: unit -> t = "caml_console_start_page"
    external zero: Istring.Raw.t -> unit = "caml_console_ring_init"
    external unsafe_write: t -> string -> int -> int = "caml_console_ring_write"
    external unsafe_read: t -> string -> int -> int = "caml_console_ring_read"
    let alloc domid = alloc_raw zero domid
    let alloc_initial () =
      let num = initial_grant_num in
      let page = start_page () in
      let gnt = Gnttab.alloc ~page num in
      gnt, page
end

module Xenstore = struct
    type t = Istring.Raw.t
    let initial_grant_num : Gnttab.num = 1l
    external start_page: unit -> t = "caml_xenstore_start_page"
    external zero: Istring.Raw.t -> unit = "caml_xenstore_ring_init"
    external unsafe_write: t -> string -> int -> int = "caml_xenstore_ring_write"
    external unsafe_read: t -> string -> int -> int = "caml_xenstore_ring_read"
    let alloc_initial () =
      let num = initial_grant_num in
      let page = start_page () in
      zero page;
      let gnt = Gnttab.alloc ~page num in
      gnt, page
end
