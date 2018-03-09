(*
 * Copyright (c) 2015 Gabriel Radanne <drupyog@zoho.com>
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

(** Mirage keys.

 {e Release %%VERSION%% } *)

module Arg : sig
  include module type of struct include Functoria_key.Arg end

  val ipv4_address : Ipaddr.V4.t converter
  val ipv4 : (Ipaddr.V4.Prefix.t * Ipaddr.V4.t) converter
  val ipv6 : Ipaddr.V6.t converter
  val ipv6_prefix : Ipaddr.V6.Prefix.t converter

end

include Functoria.KEY with module Arg := Arg

type mode = [ `Unix | `Xen | `Qubes | `MacOSX | `Virtio | `Ukvm | `Muen ]

(** {2 Mirage keys} *)

val target: mode key
(** [-t TARGET]: Key setting the configuration mode for the current project.
    Is one of ["unix"], ["macosx"], ["xen"], ["qubes"], ["virtio"], ["ukvm"]
    or ["muen"].
*)

val pp_target: mode Fmt.t
(** Pretty printer for the mode. *)

val is_unix: bool value
(** Is true iff the {!target} key is a UNIXish system (["unix" or "macosx"]).
*)

val warn_error: bool key
(** [--warn-error]. Enable {i -warn-error} for OCaml sources. Set to [false] by
    default, but might might enabled by default in later releases. *)

val target_debug: bool key
(** Enables target-specific support for debugging. *)

val tracing_size: int -> int key
(** [--tracing-size]: Key setting the tracing ring buffer size. *)

(** {2 Generic keys}

    Some keys have a [group] optional argument. This group argument allows to
    give several keys a prefix.

    For example, if we have two [ip] stacks, one external and one internal,
    We can use the [group] option to name them [in] and [out]. This way, the
    available keys will be [--in-ip] and [--out-ip].

    If a key has another, non-optional argument. It is the default value.

    Keys are always named the same as their command line option.

    {3 File system keys} *)

val kv_ro : ?group:string -> unit -> [ `Archive | `Crunch | `Direct | `Fat ] key
(** The type of key value store.
    Is one of ["archive"], ["crunch"], ["direct"], or ["fat"]. *)

(** {3 Block device keys} *)
val block : ?group:string -> unit -> [ `XenstoreId | `BlockFile | `Ramdisk ] key

(** {3 PRNG key} *)

val prng : ?group:string -> unit -> [ `Stdlib | `Nocrypto ] key
(** The type of pseudo random number generator to use by default.
    Is one of ["stdlib"] (lagged Fibonacci), or ["nocrypto"] (Fortuna). *)

(** {3 Stack keys} *)

val dhcp : ?group:string -> unit -> bool key
(** Enable dhcp. Is either [true] or [false]. *)

val net : ?group:string -> unit -> [ `Direct | `Socket ] key
(** The type of stack. Is either ["direct"] or ["socket"]. *)

(** {3 Network keys} *)

val interface : ?group:string -> string -> string key
(** A network interface. *)

(** Ipv4 keys. *)
module V4 : sig
  open Ipaddr.V4

  val network : ?group:string -> (Prefix.t * t)-> (Prefix.t * t) key
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> t option -> t option key
  (** A default gateway option. *)

  val socket : ?group:string -> t option -> t option key
  (** An address bound by a socket. Will be none if no address is provided. *)

  val interfaces : ?group:string -> t list -> t list key
  (** A list of interfaces bound by a socket. *)

end

(** Ipv6 keys. *)
module V6 : sig
  open Ipaddr.V6

  val ips : ?group:string -> t list -> t list key
  (** An ip address. *)

  val netmasks : ?group:string -> Prefix.t list -> Prefix.t list key
  (** A list of netmasks. *)

  val gateways : ?group:string -> t list -> t list key
  (** A list of gateways. *)

end

val syslog: Ipaddr.V4.t option -> Ipaddr.V4.t option key
(** The address to send syslog frames to. *)

val syslog_port: int option -> int option key
(** The port to send syslog frames to. *)

val syslog_hostname: string -> string key
(** The hostname to use in syslog frames. *)

val logs: Mirage_runtime.log_threshold list key
