(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

(*
module type RING = sig
  type req
  type res
  type fring

  val alloc : int -> (Gnttab.r * fring) Lwt.t
  val pending_responses : fring -> int
  val free_requests : fring -> int
  val max_requests : fring -> int
  val write : fring -> req list -> bool
  val read : fring -> res list
  val id_of_res : res -> int
end

module Netif : sig
  module Rx : sig
    module Req : sig
      type t = {
       id: int;
       gref: int32; 
      } 
    end
    module Res : sig
      type flags = {
        checksum_blank: bool;
        data_validated: bool;
        more_data: bool;
        extra_info: bool;
      }
      type status = 
        | Size of int
        | Err of int
      type t = { id : int; off : int; flags : flags; status : status; }
    end
    type req = Req.t
    type res = Res.t
    type fring
    val alloc: int -> (Gnttab.r * fring) Lwt.t (* Allocate a ring *)
    val pending_responses: fring -> int   (* Pending responses *)
    val free_requests: fring -> int       (* Available req slots *)
    val max_requests: fring -> int        (* Max req slots *)

    val write: fring -> req list -> bool  (* Write requests to ring *)
    val read: fring -> res list           (* Read responses from ring *)
 
  end

  module Rx_t : sig
    type id = int
    type t
    val t : backend_domid:int -> (Gnttab.r * t) Lwt.t
    val push : t -> evtchn:int -> (id -> Rx.Req.t * (Rx.Res.t -> unit Lwt.t)) list -> unit Lwt.t
    val push_one : t -> evtchn:int -> (id -> Rx.Req.t) -> Rx.Res.t Lwt.t
    val poll : t -> unit
    val pending_responses : t -> int
    val max_requests : t -> int
    val free_requests : t -> int
  end

  module Tx : sig
    module Req : sig
      type gso_type =
        | GSO_none
        | GSO_TCPv4

      type gso = {
        gso_size: int;
        gso_type: gso_type;
        gso_features: int;
      }

      type extra =
        | GSO of gso
        | Mcast_add of string
        | Mcast_del of string

      type flags = int

      type normal = {
        gref: int32;
        offset: int;
        flags: flags;
        id: int;
        size: int;
      }

      type t =
       | Normal of normal 
       | Extra of extra
    end

    module Res : sig
      type status =  
       | Dropped | Error | OK | Null
      type t = { id : int; status: status; }
    end
  end

  module Tx_t : sig
    type id = int
    type t
    val t : backend_domid:int -> (Gnttab.r * t) Lwt.t
    val push_one : t -> evtchn:int -> (id -> Tx.Req.t) -> Tx.Res.t Lwt.t
    val poll : t -> unit
    val pending_responses : t -> int
    val max_requests : t -> int
    val free_requests : t -> int
  end
end

module Blkif : sig
  type id = int
  type vdev = int

  module Req : sig
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

  module Res : sig
    type status = 
      |OK |Error |Not_supported |Unknown of int

    type t = {
      id: int;
      op: Req.op;
      status: status;
    }
  end
end  

module Blkif_t : sig
  type id = int
  type t
  val t : backend_domid:int -> (Gnttab.r * t) Lwt.t
  val push_one : t -> evtchn:int -> (id -> Blkif.Req.t) -> Blkif.Res.t Lwt.t
  val poll : t -> unit
  val pending_responses : t -> int
  val max_requests : t -> int
  val free_requests : t -> int
end

*) 

val alloc: int -> (Gnttab.r * Bitstring.t) Lwt.t
type sring

val init : Bitstring.t -> idx_size:int -> name:string -> sring
val nr_ents: sring -> int
val slot : sring -> int -> Bitstring.t

module Front : sig
  type t
  val init : sring:sring -> t
  val get_free_requests : t -> int
  val ring_full : t -> bool
  val has_unconsumed_responses : t -> bool
  val push_requests : t -> unit
  val push_requests_and_check_notify : t -> bool
  val check_for_responses : t -> bool
end

module Console : sig
  type t
  external unsafe_write : t -> string -> int -> int = "caml_console_ring_write"
  external unsafe_read : t -> string -> int -> int = "caml_console_ring_read"
  val alloc_initial : unit -> Gnttab.r * t
end

module Xenstore : sig
  type t
  external unsafe_write : t -> string -> int -> int = "caml_xenstore_ring_write"
  external unsafe_read : t -> string -> int -> int = "caml_xenstore_ring_read"
  val alloc_initial : unit -> Gnttab.r * t
end
