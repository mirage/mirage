type netfront
type netfront_id
(** Get a list of all the available Netfronts ids
  *)
val enumerate: Xs.xsh -> netfront_id list Lwt.t

(** Create a netfront Ethernet interface
  * xenstore -> id -> receive function -> netfront *)
val create: Xs.xsh -> netfront_id -> netfront Lwt.t

(** Add a receive callback function to this netfront. *)
val set_recv : netfront -> (string -> unit) -> unit

(** Transmit a packet; can block
  * netfront -> buffer -> offset -> length -> unit Lwt.t
  *)
val xmit: netfront -> string -> int -> int -> unit Lwt.t

(** Return an Ethernet MAC address for a netfront *)
val mac: netfront -> string
