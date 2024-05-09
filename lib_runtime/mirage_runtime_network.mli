open Cmdliner

(** {1 Command-line arguments for network devices} *)

(** This module is the runtime counter-part of the network command-line
    arguments defined in [Mirage_runtime_arg]. Both modules should be kept in
    sync. *)

val interface : ?group:string -> ?docs:string -> string -> string Term.t
(** A network interface, [docs] defaults to {!Mirage_runtime.s_net}. *)

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
  (** A network defined by an address and netmask, [docs] defaults to
      {!Mirage_runtime.s_net}. *)

  val gateway : ?group:string -> ?docs:string -> t option -> t option Term.t
  (** A default gateway option, [docs] defaults to {!Mirage_runtime.s_net}. *)
end

(** Ipv6 Term.ts. *)
module V6 : sig
  open Ipaddr.V6

  val network :
    ?group:string -> ?docs:string -> Prefix.t option -> Prefix.t option Term.t
  (** A network defined by an address and netmask, [docs] defaults to
      {!Mirage_runtime.s_net}. *)

  val gateway : ?group:string -> ?docs:string -> t option -> t option Term.t
  (** A default gateway option, [docs] defaults to {!Mirage_runtime.s_net}. *)

  val accept_router_advertisements :
    ?group:string -> ?docs:string -> unit -> bool Term.t
  (** An option whether to accept router advertisements, [docs] defaults to
      {!Mirage_runtime.s_net}. *)
end

val ipv4_only : ?group:string -> ?docs:string -> unit -> bool Term.t
(** An option for dual stack to only use IPv4, [docs] defaults to
    {!Mirage_runtime.s_net}. *)

val ipv6_only : ?group:string -> ?docs:string -> unit -> bool Term.t
(** An option for dual stack to only use IPv6, [docs] defaults to
    {!Mirage_runtime.s_net}. *)

val resolver :
  ?group:string ->
  ?docs:string ->
  ?default:string list ->
  unit ->
  string list option Term.t
(** The address of the DNS resolver to use. See $REFERENCE for format. [docs]
    defaults to {!Mirage_runtime.s_net}. *)

val syslog :
  ?group:string -> ?docs:string -> Ipaddr.t option -> Ipaddr.t option Term.t
(** The address to send syslog frames to, [docs] defaults to
    {!Mirage_runtime.s_log}. *)

val monitor :
  ?group:string -> ?docs:string -> Ipaddr.t option -> Ipaddr.t option Term.t
(** The address to send monitor statistics to, [docs] defaults to
    {!Mirage_runtime.s_log}. *)

val syslog_port :
  ?group:string -> ?docs:string -> int option -> int option Term.t
(** The port to send syslog frames to, [docs] defaults to
    {!Mirage_runtime.s_log}. *)

val syslog_hostname : ?group:string -> ?docs:string -> string -> string Term.t
(** The hostname to use in syslog frames, [docs] defaults to
    {!Mirage_runtime.s_log}. *)
