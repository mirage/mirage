open Cmdliner

(** {1 Command-line arguments for network devices} *)

(** This module is the runtime counter-part of the network command-line
    arguments defined in [Mirage_runtime_arg]. Both modules should be kept in
    sync.

    In all the function in this module, [docs] is ["UNIKERNEL PARAMETERS"] if
    not set. *)

val interface : ?group:string -> ?docs:string -> string -> string Term.t
(** A network interface. *)

(** [Cmdliner.Arg] converters for [Ipadrr] types. *)
module Arg : sig
  val ipv4_address : Ipaddr.V4.t Arg.conv
  val ipv4 : Ipaddr.V4.Prefix.t Arg.conv
  val ipv6_address : Ipaddr.V6.t Arg.conv
  val ipv6 : Ipaddr.V6.Prefix.t Arg.conv
  val ip_address : Ipaddr.t Arg.conv
end

(** Ipv4 Terms *)
module V4 : sig
  open Ipaddr.V4

  val network : ?group:string -> ?docs:string -> Prefix.t -> Prefix.t Term.t
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> ?docs:string -> t option -> t option Term.t
  (** A default gateway option. *)
end

(** Ipv6 Term.ts. *)
module V6 : sig
  open Ipaddr.V6

  val network :
    ?group:string -> ?docs:string -> Prefix.t option -> Prefix.t option Term.t
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> ?docs:string -> t option -> t option Term.t
  (** A default gateway option. *)

  val accept_router_advertisements :
    ?group:string -> ?docs:string -> unit -> bool Term.t
  (** An option whether to accept router advertisements. *)
end

val ipv4_only : ?group:string -> ?docs:string -> unit -> bool Term.t
(** An option for dual stack to only use IPv4. *)

val ipv6_only : ?group:string -> ?docs:string -> unit -> bool Term.t
(** An option for dual stack to only use IPv6. *)

val resolver :
  ?group:string ->
  ?docs:string ->
  ?default:string list ->
  unit ->
  string list option Term.t
(** The address of the DNS resolver to use. See $REFERENCE for format. *)

val syslog :
  ?group:string -> ?docs:string -> Ipaddr.t option -> Ipaddr.t option Term.t
(** The address to send syslog frames to. *)

val monitor :
  ?group:string -> ?docs:string -> Ipaddr.t option -> Ipaddr.t option Term.t
(** The address to send monitor statistics to. *)

val syslog_port :
  ?group:string -> ?docs:string -> int option -> int option Term.t
(** The port to send syslog frames to. *)

val syslog_hostname : ?group:string -> ?docs:string -> string -> string Term.t
(** The hostname to use in syslog frames. *)
