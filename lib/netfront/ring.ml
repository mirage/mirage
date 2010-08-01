(** Type-safe OCaml wrapper for single-page Xen I/O rings
    Every ring is a 4K page, with separate types for requests
    and responses. The size of the number of requests is cunningly
    set to a power of 2, so the producer/consumer ints can wrap
    safely without needing to mask them. *)

(* For every ring, we need to have bindings that define the type
   of a request and response, and accessor functions for those
   structs to set fields.  Note that this will directly write to 
   that entry in the ring, without OCaml allocation involved. *)

type port = int
type ('a,'b) ring 
 
module Netif_tx = struct
    type req
    type res
    type t = (req, res) ring
    external init: Gnttab.r -> t = "caml_netif_tx_ring_init"
    external req_get: t -> int -> req = "caml_netif_tx_ring_req_get" "noalloc"
    external res_get: t -> int -> res = "caml_netif_tx_ring_res_get" "noalloc"
    external req_push: t -> int -> port -> unit = "caml_netif_tx_ring_req_push" "noalloc"
    external res_ack: t -> int -> bool = "caml_netif_tx_ring_res_ack" "noalloc"
end

module Netif_rx = struct
    type req
    type res
    type t = (req, res) ring
    external init: Gnttab.r -> t = "caml_netif_rx_ring_init"
    external req_get: t -> int -> req = "caml_netif_rx_ring_req_get" "noalloc"
    external res_get: t -> int -> res = "caml_netif_rx_ring_res_get" "noalloc"
    external req_push: t -> int -> port -> unit = "caml_netif_rx_ring_req_push" "noalloc"
    external res_ack: t -> int -> bool = "caml_netif_rx_ring_res_ack" "noalloc"
    external req_set: req -> id:int -> gref:Gnttab.r -> unit = "caml_netif_rx_ring_req_set"
    external resp_get_id: resp -> int = "caml_netif_rx_ring_resp_get_id" "noalloc"
    external resp_get_offset: resp -> int = "caml_netif_rx_ring_resp_get_offset" "noalloc"
    external resp_get_flags: resp -> int = "caml_netif_rx_ring_resp_get_flags" "noalloc"
    external resp_get_status: resp -> int = "caml_netif_rx_ring_resp_get_status" "noalloc"
end

