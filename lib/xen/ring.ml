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
    let ring = fn gnt in
    Gnttab.grant_access gnt domid Gnttab.RW;
    return (gnt, ring)

(* Read all responses on a ring, and ack them all at the end *)
let read_responses ring waiting get_cons get ack fn =
    let rec loop () = 
        let num = waiting ring in
        let cons = get_cons ring in
        for i = cons to (cons + num - 1) do
           fn i (get ring i) 
        done;
        if ack ring ~num then
           loop ()
    in loop ()

module Netif_tx = struct
    type req
    type res
    type t = (req, res) ring

    external init: Gnttab.r -> t = "caml_netif_tx_ring_init"
    external req_get: t -> int -> req = "caml_netif_tx_ring_req_get" "noalloc"
    external res_get: t -> int -> res = "caml_netif_tx_ring_res_get" "noalloc"
    external req_push: t -> int -> port -> unit = "caml_netif_tx_ring_req_push" "noalloc"
    external res_waiting: t -> int = "caml_netif_tx_ring_res_waiting" "noalloc"
    external res_get_cons: t -> int = "caml_netif_tx_ring_res_get_cons" "noalloc"
    external req_get_prod: t -> int = "caml_netif_tx_ring_req_get_prod" "noalloc"
    external res_ack: t -> num:int -> bool = "caml_netif_tx_ring_res_ack" "noalloc"
    external get_size: unit -> int = "caml_netif_tx_ring_size" "noalloc"

    external req_set: req -> offset:int -> flags:int -> id:int -> 
        size:int -> unit = "caml_netif_tx_ring_req_set" 
    external req_set_gnt: req -> Gnttab.r -> unit = "caml_netif_tx_ring_req_set_gnt"

    let size = get_size ()
    let alloc domid = alloc init domid
    let read_responses ring fn = read_responses ring res_waiting res_get_cons res_get res_ack fn
end

module Netif_rx = struct
    type req
    type res
    type t = (req, res) ring

    external init: Gnttab.r -> t = "caml_netif_rx_ring_init"
    external req_get: t -> int -> req = "caml_netif_rx_ring_req_get" "noalloc"
    external res_get: t -> int -> res = "caml_netif_rx_ring_res_get" "noalloc"
    external req_push: t -> int -> port -> unit = "caml_netif_rx_ring_req_push" "noalloc"
    external res_waiting: t -> int = "caml_netif_rx_ring_res_waiting" "noalloc"
    external res_get_cons: t -> int = "caml_netif_rx_ring_res_get_cons" "noalloc"
    external req_get_prod: t -> int = "caml_netif_rx_ring_req_get_prod" "noalloc"
    external res_ack: t -> num:int -> bool = "caml_netif_rx_ring_res_ack" "noalloc"
    external get_size: unit -> int = "caml_netif_rx_ring_size" "noalloc"

    external req_set: req -> id:int -> gnt:Gnttab.r -> unit = "caml_netif_rx_ring_req_set"
    external res_get_id: res -> int = "caml_netif_rx_ring_res_get_id" "noalloc"
    external res_get_offset: res -> int = "caml_netif_rx_ring_res_get_offset" "noalloc"
    external res_get_flags: res -> int = "caml_netif_rx_ring_res_get_flags" "noalloc"
    external res_get_status: res -> int = "caml_netif_rx_ring_res_get_status" "noalloc"

    let size = get_size ()
    let alloc domid = alloc init domid
    let read_responses ring fn = read_responses ring res_waiting res_get_cons res_get res_ack fn
end

module Console = struct
    type t
    external start_init: Gnttab.r -> t = "caml_console_start_ring_init" "noalloc"
    external init: Gnttab.r -> t = "caml_console_ring_init" "noalloc"
    external unsafe_write: t -> string -> int -> int = "caml_console_ring_write" "noalloc"
    external unsafe_read: t -> string -> int -> int = "caml_console_ring_read" "noalloc"
    let alloc domid = alloc init domid
end

module Xenstore = struct
    type t
    external start_init: Gnttab.r -> t = "caml_xenstore_start_ring_init" "noalloc"
    external unsafe_write: t -> string -> int -> int = "caml_xenstore_ring_write" "noalloc"
    external unsafe_read: t -> string -> int -> int = "caml_xenstore_ring_read" "noalloc"
end
