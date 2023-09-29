open Cmdliner

(** {3 Network keys} *)

val interface : ?group:string -> string -> string Term.t
(** A network interface. *)

(** Ipv4 Term.ts. *)
module V4 : sig
  open Ipaddr.V4

  val network : ?group:string -> Prefix.t -> Prefix.t Term.t
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> t option -> t option Term.t
  (** A default gateway option. *)
end

(** Ipv6 Term.ts. *)
module V6 : sig
  open Ipaddr.V6

  val network : ?group:string -> Prefix.t option -> Prefix.t option Term.t
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> t option -> t option Term.t
  (** A default gateway option. *)

  val accept_router_advertisements : ?group:string -> unit -> bool Term.t
  (** An option whether to accept router advertisements. *)
end

val ipv4_only : ?group:string -> unit -> bool Term.t
(** An option for dual stack to only use IPv4. *)

val ipv6_only : ?group:string -> unit -> bool Term.t
(** An option for dual stack to only use IPv6. *)

val resolver : ?default:string list -> unit -> string list option Term.t
(** The address of the DNS resolver to use. See $REFERENCE for format. *)

val syslog : Ipaddr.t option -> Ipaddr.t option Term.t
(** The address to send syslog frames to. *)

val syslog_port : int option -> int option Term.t
(** The port to send syslog frames to. *)

val syslog_hostname : string -> string Term.t
(** The hostname to use in syslog frames. *)
