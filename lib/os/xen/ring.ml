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
   structs to set fields.  Note that this will directly write to 
   that entry in the ring, without OCaml allocation involved. *)

open Lwt
type port = int
type ('a,'b) ring 

(* Allocate a new grant entry and initialise a ring using it *)
let alloc fn domid =
  lwt gnt = Gnttab.get_free_entry () in
  let page = Istring.Raw.alloc () in
  Gnttab.attach gnt page;
  let ring = fn page in
  let perm = Gnttab.RW in
  Gnttab.grant_access ~domid ~perm gnt;
  return (gnt, ring)

(* Read all responses on a ring, and ack them all at the end *)
let read_responses ring waiting get_cons get ack fn =
  let res = ref [] in
  let rec loop () = 
    let num = waiting ring in
    let cons = get_cons ring in
    for i = cons to (cons + num - 1) do
      res := (fn i (get ring i)) :: !res
    done;
    if ack ring ~num then
      loop ()
  in
  loop ();
  List.rev !res

module Netif_tx = struct
  type req
  type res
  type t = (req, res) ring

  external init: Istring.Raw.t -> t = "caml_netif_tx_ring_init"
  external req_get: t -> int -> req = "caml_netif_tx_ring_req_get" 
  external res_get: t -> int -> res = "caml_netif_tx_ring_res_get"
  external req_push: t -> int -> port -> unit = "caml_netif_tx_ring_req_push" 
  external res_waiting: t -> int = "caml_netif_tx_ring_res_waiting"
  external res_get_cons: t -> int = "caml_netif_tx_ring_res_get_cons"
  external req_get_prod: t -> int = "caml_netif_tx_ring_req_get_prod"
  external res_ack: t -> num:int -> bool = "caml_netif_tx_ring_res_ack"
  external get_size: unit -> int = "caml_netif_tx_ring_size"

  external req_set: req -> offset:int -> flags:int -> id:int -> 
        size:int -> unit = "caml_netif_tx_ring_req_set" 
  external req_set_gnt_num: req -> Gnttab.num -> unit = "caml_netif_tx_ring_req_set_gnt"
  let req_set_gnt req ~gnt = req_set_gnt_num req (Gnttab.num gnt)
  let size = get_size ()
  let alloc domid = alloc init domid
  let read_responses ring fn =
    read_responses ring res_waiting res_get_cons res_get res_ack fn
end

module Netif_rx = struct
    type req
    type res
    type t = (req, res) ring

    external init: Istring.Raw.t -> t = "caml_netif_rx_ring_init"
    external req_get: t -> int -> req = "caml_netif_rx_ring_req_get"
    external res_get: t -> int -> res = "caml_netif_rx_ring_res_get"
    external req_push: t -> int -> port -> unit = "caml_netif_rx_ring_req_push"
    external res_waiting: t -> int = "caml_netif_rx_ring_res_waiting"
    external res_get_cons: t -> int = "caml_netif_rx_ring_res_get_cons"
    external req_get_prod: t -> int = "caml_netif_rx_ring_req_get_prod"
    external res_ack: t -> num:int -> bool = "caml_netif_rx_ring_res_ack"
    external get_size: unit -> int = "caml_netif_rx_ring_size" 

    external req_set_num: req -> id:int -> Gnttab.num -> unit = "caml_netif_rx_ring_req_set"
    let req_set req ~id ~gnt = req_set_num req ~id (Gnttab.num gnt)
    external res_get_id: res -> int = "caml_netif_rx_ring_res_get_id"
    external res_get_offset: res -> int = "caml_netif_rx_ring_res_get_offset"
    external res_get_flags: res -> int = "caml_netif_rx_ring_res_get_flags"
    external res_get_status: res -> int = "caml_netif_rx_ring_res_get_status"

    let size = get_size ()
    let alloc domid = alloc init domid
    let read_responses ring fn = read_responses ring res_waiting res_get_cons res_get res_ack fn
end

module Console = struct
    type t = Istring.Raw.t
    let initial_grant_num : Gnttab.num = 2l
    external start_page: unit -> t = "caml_console_start_page"
    external init: Istring.Raw.t -> t = "caml_console_ring_init"
    external unsafe_write: t -> string -> int -> int = "caml_console_ring_write"
    external unsafe_read: t -> string -> int -> int = "caml_console_ring_read"
    let alloc domid = alloc init domid
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
    external unsafe_write: t -> string -> int -> int = "caml_xenstore_ring_write"
    external unsafe_read: t -> string -> int -> int = "caml_xenstore_ring_read"
    let alloc_initial () =
      let num = initial_grant_num in
      let page = start_page () in
      let gnt = Gnttab.alloc ~page num in
      gnt, page
end
