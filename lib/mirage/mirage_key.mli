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
  val ipv4 : Ipaddr.V4.Prefix.t converter
  val ipv6_address : Ipaddr.V6.t converter
  val ipv6 : Ipaddr.V6.Prefix.t converter
  val ip_address : Ipaddr.t converter
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

(** {2 OCaml runtime keys}

    The OCaml runtime is usually configurable via the [OCAMLRUNPARAM]
    environment variable. We provide boot parameters covering these options. *)

val backtrace : bool key
(** [--backtrace]: Output a backtrace if an uncaught exception terminated the
    unikernel. *)

val randomize_hashtables : bool key
(** [--randomize-hashtables]: Randomize all hash tables. *)

(** {3 GC control}

    The OCaml garbage collector can be configured, as described in detail in
    {{:http://caml.inria.fr/pub/docs/manual-ocaml/libref/Gc.html#TYPEcontrol} GC
      control}.

    The following keys allow boot time configuration. *)

val allocation_policy : [ `Next_fit | `First_fit | `Best_fit ] key
val minor_heap_size : int option key
val major_heap_increment : int option key
val space_overhead : int option key
val max_space_overhead : int option key
val gc_verbosity : int option key
val gc_window_size : int option key
val custom_major_ratio : int option key
val custom_minor_ratio : int option key
val custom_minor_max_size : int option key

(** {2 Generic keys}

    Some keys have a [group] optional argument. This group argument allows to
    give several keys a prefix.

    For example, if we have two [ip] stacks, one external and one internal, We
    can use the [group] option to name them [in] and [out]. This way, the
    available keys will be [--in-ip] and [--out-ip].

    If a key has another, non-optional argument. It is the default value.

    Keys are always named the same as their command line option. *)

(** {3 Startup delay} *)

val delay : int key
(** The initial delay, specified in seconds, before a unikernel starting up.
    Defaults to 0. Useful for tenders and environments that take some time to
    bring devices up. *)

(** {3 File system keys} *)

val kv_ro : ?group:string -> unit -> [ `Crunch | `Direct ] key
(** The type of key value store. Is one of ["crunch"], or ["direct"]. *)

val block : ?group:string -> unit -> [ `XenstoreId | `BlockFile | `Ramdisk ] key
(** {3 Block device keys} *)

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

  val network : ?group:string -> Prefix.t -> Prefix.t key
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> t option -> t option key
  (** A default gateway option. *)
end

(** Ipv6 keys. *)
module V6 : sig
  open Ipaddr.V6

  val network : ?group:string -> Prefix.t option -> Prefix.t option key
  (** A network defined by an address and netmask. *)

  val gateway : ?group:string -> t option -> t option key
  (** A default gateway option. *)

  val accept_router_advertisements : ?group:string -> unit -> bool key
  (** An option whether to accept router advertisements. *)
end

val ipv4_only : ?group:string -> unit -> bool key
(** An option for dual stack to only use IPv4. *)

val ipv6_only : ?group:string -> unit -> bool key
(** An option for dual stack to only use IPv6. *)

val resolver : ?default:string list -> unit -> string list option key
(** The address of the DNS resolver to use. See $REFERENCE for format. *)

val syslog : Ipaddr.t option -> Ipaddr.t option key
(** The address to send syslog frames to. *)

val syslog_port : int option -> int option key
(** The port to send syslog frames to. *)

val syslog_hostname : string -> string key
(** The hostname to use in syslog frames. *)

val logs : Mirage_runtime.log_threshold list key
