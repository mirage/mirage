(*
 * Copyright (c) 2023 Thomas Gazagnaire <thomas@gazagnaire.org>
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

(** Command-line arguments for Mirage applications. *)

open Functoria.DSL
include module type of Functoria.Runtime_arg

type 'a arg = 'a runtime_arg
(** The type for command-line arguments that reads a value of type ['a]. *)

val create :
  pos:string * int * int * int -> ?packages:package list -> string -> 'a arg

val v : 'a arg -> Functoria.Runtime_arg.t
(** [v k] is the [k] with its type hidden. *)

(** {3 Network Arguments} *)

val interface : ?group:string -> ?docs:string -> string -> string runtime_arg
(** A network interface. *)

(** Ipv4 Arguments. *)
module V4 : sig
  open Ipaddr.V4

  val network :
    ?group:string -> ?docs:string -> Prefix.t -> Prefix.t runtime_arg
  (** A network defined by an address and netmask. *)

  val gateway :
    ?group:string -> ?docs:string -> t option -> t option runtime_arg
  (** A default gateway option. *)
end

(** Ipv6 Arguments. *)
module V6 : sig
  open Ipaddr.V6

  val network :
    ?group:string ->
    ?docs:string ->
    Prefix.t option ->
    Prefix.t option runtime_arg
  (** A network defined by an address and netmask. *)

  val gateway :
    ?group:string -> ?docs:string -> t option -> t option runtime_arg
  (** A default gateway option. *)

  val accept_router_advertisements :
    ?group:string -> ?docs:string -> unit -> bool runtime_arg
  (** An option whether to accept router advertisements. *)
end

val ipv4_only : ?group:string -> ?docs:string -> unit -> bool runtime_arg
(** An option for dual stack to only use IPv4. *)

val ipv6_only : ?group:string -> ?docs:string -> unit -> bool runtime_arg
(** An option for dual stack to only use IPv6. *)

val resolver :
  ?group:string ->
  ?docs:string ->
  ?default:string list ->
  unit ->
  string list option runtime_arg
(** The address of the DNS resolver to use. See $REFERENCE for format. *)

val dns_servers :
  ?group:string ->
  ?docs:string ->
  string list option ->
  string list option runtime_arg
(** The addresses of the DNS servers to use. *)

val dns_timeout :
  ?group:string -> ?docs:string -> int64 option -> int64 option runtime_arg
(** The timeout (in nanoseconds) for DNS resolution. *)

val dns_cache_size :
  ?group:string -> ?docs:string -> int option -> int option runtime_arg
(** The cache size of the LRU cache used for DNS resolution. *)

val he_aaaa_timeout :
  ?group:string -> ?docs:string -> int64 option -> int64 option runtime_arg
(** The timeout (in nanoseconds) for IPv6 resolution. *)

val he_connect_delay :
  ?group:string -> ?docs:string -> int64 option -> int64 option runtime_arg
(** The delay (in nanoseconds) for establishing connections. *)

val he_connect_timeout :
  ?group:string -> ?docs:string -> int64 option -> int64 option runtime_arg
(** The timeout (in nanoseconds) for establishing connections. *)

val he_resolve_timeout :
  ?group:string -> ?docs:string -> int64 option -> int64 option runtime_arg
(** The timeout (in nanoseconds) for resolving hostnames. *)

val he_resolve_retries :
  ?group:string -> ?docs:string -> int option -> int option runtime_arg
(** The number of resolution attempts before an error is returned. *)

val he_timer_interval :
  ?group:string -> ?docs:string -> int64 option -> int64 option runtime_arg
(** The interval (in nanoseconds) when the timer is executed. *)

val ssh_key :
  ?group:string -> ?docs:string -> string option -> string option runtime_arg
(** A SSH private key. *)

val ssh_password :
  ?group:string -> ?docs:string -> string option -> string option runtime_arg
(** A SSH password. *)

val ssh_authenticator :
  ?group:string -> ?docs:string -> string option -> string option runtime_arg
(** A SSH authenticator. *)

val tls_authenticator :
  ?group:string -> ?docs:string -> string option -> string option runtime_arg
(** A TLS authenticator. *)

val http_headers :
  ?group:string ->
  ?docs:string ->
  (string * string) list option ->
  (string * string) list option runtime_arg
(** HTTP headers. *)

val syslog :
  ?group:string ->
  ?docs:string ->
  Ipaddr.t option ->
  Ipaddr.t option runtime_arg
(** The address to send syslog frames to. *)

val syslog_port : ?group:string -> ?docs:string -> int option -> int runtime_arg
(** The port to send syslog frames to. *)

val syslog_truncate :
  ?group:string -> ?docs:string -> int option -> int option runtime_arg
(** Truncate syslog frames to a specific byte count, [docs] defaults to
    {!Mirage_runtime.s_log}. *)

val syslog_keyname :
  ?group:string -> ?docs:string -> string option -> string option runtime_arg
(** TLS key used for syslog, [docs] defaults to {!Mirage_runtime.s_log}. *)

val monitor :
  ?group:string ->
  ?docs:string ->
  Ipaddr.t option ->
  Ipaddr.t option runtime_arg
(** The address to send monitor statistics to. *)

(** {3 Logs} *)

type log_threshold = [ `All | `Src of string ] * Logs.level option
(** The type for log threshold. A log level of [None] disables logging. *)

val logs : log_threshold list runtime_arg

(** {3 Startup delay} *)

val delay : int runtime_arg
(** The initial delay, specified in seconds, before a unikernel starting up.
    Defaults to 0. Useful for tenders and environments that take some time to
    bring devices up. *)
