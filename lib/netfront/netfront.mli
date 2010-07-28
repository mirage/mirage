type netfront
type netfront_id
(** Get a list of all the available Netfronts ids
  *)
val enumerate: Xs.xsh -> netfront_id list Lwt.t

(** Create a netfront Ethernet interface
  * xenstore -> id -> receive function -> netfront *)
val create: Xs.xsh -> netfront_id -> (string -> unit) -> netfront Lwt.t

(** Transmit a packet; can block
  * netfront -> buffer -> offset -> length -> unit Lwt.t
  *)
val xmit: netfront -> string -> int -> int -> unit Lwt.t
