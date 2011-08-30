module Event :
  sig
    type t = DATAPATH_JOIN | DATAPATH_LEAVE | PACKET_IN
    type e =
        Datapath_join of Ofpacket.datapath_id
      | Datapath_leave of Ofpacket.datapath_id
      | Packet_in of Ofpacket.port * Bitstring.t * Ofpacket.datapath_id
    val string_of_event : e -> string
  end
type endhost = { ip : Net.Nettypes.ipv4_addr; port : int; }
type state = {
  mutable dp_db : (Ofpacket.datapath_id, Net.Channel.t) Hashtbl.t;
  mutable channel_dp : (endhost, Ofpacket.datapath_id) Hashtbl.t;
  mutable datapath_join_cb :
    (state -> Ofpacket.datapath_id -> Event.e -> unit) list;
  mutable datapath_leave_cb :
    (state -> Ofpacket.datapath_id -> Event.e -> unit) list;
  mutable packet_in_cb : (state -> Ofpacket.datapath_id -> Event.e -> unit) list;
}
val register_cb :
  state -> Event.t -> (state -> Ofpacket.datapath_id -> Event.e -> unit) -> unit
val process_of_packet :
  state ->
  Net.Nettypes.ipv4_addr * int -> Ofpacket.t -> Net.Channel.t -> unit Lwt.t
val send_of_data : state -> Ofpacket.datapath_id -> Bitstring.t -> unit Lwt.t
val rd_data : int -> Net.Channel.t -> Bitstring.bitstring Lwt.t
val listen :
  Net.Manager.t ->
  Net.Nettypes.ipv4_addr option -> int -> (state -> 'a) -> unit Lwt.t
