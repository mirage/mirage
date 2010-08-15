module Op :
  sig
    type operation =
      Xb_op.operation =
        Debug
      | Directory
      | Read
      | Getperms
      | Watch
      | Unwatch
      | Transaction_start
      | Transaction_end
      | Introduce
      | Release
      | Getdomainpath
      | Write
      | Mkdir
      | Rm
      | Setperms
      | Watchevent
      | Error
      | Isintroduced
      | Resume
      | Set_target
      | Restrict
    val operation_c_mapping : operation array
    val size : int
    external get_internal_offset : unit -> int = "stub_get_internal_offset"
    val offset_pq : int
    val operation_c_mapping_pq : operation array
    val size_pq : int
    val array_search : 'a -> 'a array -> int
    val of_cval : int -> operation
    val to_cval : operation -> int
    val to_string : operation -> string
  end
module Packet :
  sig
    type t =
      Xs_packet.t = {
      tid : int;
      rid : int;
      ty : Xb_op.operation;
      data : string;
    }
    exception Error of string
    exception DataError of string
    external string_of_header : int -> int -> int -> int -> string
      = "stub_string_of_header"
    val create : int -> int -> Xb_op.operation -> string -> t
    val of_partialpkt : Xb_partial.pkt -> t
    val to_string : t -> string
    val unpack : t -> int * int * Xb_op.operation * string
    val get_tid : t -> int
    val get_ty : t -> Xb_op.operation
    val get_data : t -> string
    val get_rid : t -> int
  end
module State :
  sig
    type state =
        Unknown
      | Initialising
      | InitWait
      | Initialised
      | Connected
      | Closing
      | Closed
      | Reconfiguring
      | Reconfigured
    val of_string : string -> state
    val to_string : state -> string
  end

exception End_of_file
exception Eagain
exception Noent
exception Invalid
type backend
type partial_buf = HaveHdr of Xb_partial.pkt | NoHdr of int * string
type t = {
  backend : backend;
  pkt_in : Packet.t Queue.t;
  pkt_out : Packet.t Queue.t;
  mutable partial_in : partial_buf;
  mutable partial_out : string;
}
val init_partial_in : unit -> partial_buf
val queue : t -> Packet.t -> unit
val read : t -> string -> int -> int Lwt.t
val write : t -> string -> int -> int Lwt.t
val output : t -> bool Lwt.t
val input : t -> bool Lwt.t
val init : unit -> t
val output_len : t -> int
val has_new_output : t -> bool
val has_old_output : t -> bool
val has_output : t -> bool
val peek_output : t -> Packet.t
val input_len : t -> int
val has_in_packet : t -> bool
val get_in_packet : t -> Packet.t
