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

type 'a arg = 'a runtime_arg
(** The type for command-line arguments that reads a value of type ['a]. *)

val create :
  pos:string * int * int * int ->
  ?name:string ->
  ?packages:package list ->
  string ->
  'a arg

val v : 'a arg -> Functoria.Runtime_arg.t
(** [v k] is the [k] with its type hidden. *)

(** {2 OCaml Arguments}

    The OCaml runtime is usually configurable via the [OCAMLRUNPARAM]
    environment variable. We provide boot parameters covering these options. *)

val backtrace : bool runtime_arg
(** [--backtrace]: Output a backtrace if an uncaught exception terminated the
    unikernel. *)

val randomize_hashtables : bool runtime_arg
(** [--randomize-hashtables]: Randomize all hash tables. *)

(** {3 GC control}

    The OCaml garbage collector can be configured, as described in detail in
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Gc.html#TYPEcontrol} GC
      control}.

    The following arguments allow boot time configuration. *)

val allocation_policy : [ `Next_fit | `First_fit | `Best_fit ] runtime_arg
val minor_heap_size : int option runtime_arg
val major_heap_increment : int option runtime_arg
val space_overhead : int option runtime_arg
val max_space_overhead : int option runtime_arg
val gc_verbosity : int option runtime_arg
val gc_window_size : int option runtime_arg
val custom_major_ratio : int option runtime_arg
val custom_minor_ratio : int option runtime_arg
val custom_minor_max_size : int option runtime_arg

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

val syslog :
  ?group:string ->
  ?docs:string ->
  Ipaddr.t option ->
  Ipaddr.t option runtime_arg
(** The address to send syslog frames to. *)

val monitor :
  ?group:string ->
  ?docs:string ->
  Ipaddr.t option ->
  Ipaddr.t option runtime_arg
(** The address to send monitor statistics to. *)

val syslog_port :
  ?group:string -> ?docs:string -> int option -> int option runtime_arg
(** The port to send syslog frames to. *)

val syslog_hostname :
  ?group:string -> ?docs:string -> string -> string runtime_arg
(** The hostname to use in syslog frames. *)

(** {3 Logs} *)

type log_threshold = [ `All | `Src of string ] * Logs.level option
(** The type for log threshold. A log level of [None] disables logging. *)

val logs : log_threshold list runtime_arg

(** {3 Startup delay} *)

val delay : int runtime_arg
(** The initial delay, specified in seconds, before a unikernel starting up.
    Defaults to 0. Useful for tenders and environments that take some time to
    bring devices up. *)
