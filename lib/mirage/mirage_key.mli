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

    {e Release %%VERSION%%} *)

module Arg : sig
  include module type of struct
    include Functoria.Key.Arg
  end

  val ipv4_address : Ipaddr.V4.t converter

  val ipv4 : (Ipaddr.V4.Prefix.t * Ipaddr.V4.t) converter

  val ipv6 : Ipaddr.V6.t converter

  val ipv6_prefix : Ipaddr.V6.Prefix.t converter
end

include Functoria.KEY with module Arg := Arg

val abstract : 'a key -> t [@@ocaml.deprecated "Use Mirage.Key.v."]

type mode_unix = [ `Unix | `MacOSX ]

type mode_xen = [ `Xen | `Qubes ]

type mode_solo5 = [ `Hvt | `Spt | `Virtio | `Muen | `Genode ]

type mode = [ mode_unix | mode_xen | mode_solo5 ]

(** {2 Mirage keys} *)

val target : mode key
(** [-t TARGET]: Key setting the configuration mode for the current project. Is
    one of ["unix"], ["macosx"], ["xen"], ["qubes"], ["virtio"], ["hvt"],
    ["muen"], ["genode"] or ["spt"]. *)

val pp_target : mode Fmt.t
(** Pretty printer for the mode. *)

val is_unix : bool value
(** Is true iff the {!target} key is a UNIXish system (["unix" or "macosx"]). *)

val is_solo5 : bool value
(** Is true iff the {!target} key is a Solo5-based target. *)

val is_xen : bool value
(** Is true iff the {!target} key is a Xen-based system (["xen" or "qubes"]). *)

val warn_error : bool key
(** [--warn-error]. Enable {i -warn-error} for OCaml sources. Set to [false] by
    default, but might might enabled by default in later releases. *)

val target_debug : bool key
(** [-g]. Enables target-specific support for debugging. *)

val tracing_size : int -> int key
(** [--tracing-size]: Key setting the tracing ring buffer size. *)

(** {2 Generic keys}

    Some keys have a [group] optional argument. This group argument allows to
    give several keys a prefix.

    For example, if we have two [ip] stacks, one external and one internal, We
    can use the [group] option to name them [in] and [out]. This way, the
    available keys will be [--in-ip] and [--out-ip].

    If a key has another, non-optional argument. It is the default value.

    Keys are always named the same as their command line option.

    {3 File system keys} *)

val kv_ro : ?group:string -> unit -> [ `Archive | `Crunch | `Direct | `Fat ] key
(** The type of key value store. Is one of ["archive"], ["crunch"], ["direct"],
    or ["fat"]. *)

val block : ?group:string -> unit -> [ `XenstoreId | `BlockFile | `Ramdisk ] key
(** {3 Block device keys} *)

(** {3 PRNG key} *)

val prng : [ `Stdlib | `Nocrypto ] key
(** The type of pseudo random number generator to use by default. *)

(** {3 Stack keys} *)

val dhcp : ?group:string -> unit -> bool key
(** Enable dhcp. Is either [true] or [false]. *)

val net : ?group:string -> unit -> [ `Direct | `Socket ] option key
(** The type of stack. Is either ["direct"] or ["socket"]. *)

(** {3 Network keys} *)

val interface : ?group:string -> string -> string key
(** A network interface. *)

(** Ipv4 keys. *)
module V4 : sig
  open Ipaddr.V4

  val network : ?group:string -> Prefix.t * t -> (Prefix.t * t) key
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> t option -> t option key
  (** A default gateway option. *)

  val socket : ?group:string -> t option -> t option key
  (** An IPv4 address bound by a socket. Will be none if no address is provided. *)

  val ips : ?group:string -> t list -> t list key
  (** A list of IPv4 addresses bound by a socket. *)
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

val resolver : ?default:Ipaddr.V4.t -> unit -> Ipaddr.V4.t key
(** The address of the DNS resolver to use. *)

val resolver_port : ?default:int -> unit -> int key
(** The port of the DNS resolver. *)

val syslog : Ipaddr.V4.t option -> Ipaddr.V4.t option key
(** The address to send syslog frames to. *)

val syslog_port : int option -> int option key
(** The port to send syslog frames to. *)

val syslog_hostname : string -> string key
(** The hostname to use in syslog frames. *)

val logs : Mirage_runtime.log_threshold list key
