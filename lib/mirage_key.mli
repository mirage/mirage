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

module Arg : sig
  include module type of struct include Functoria_key.Arg end

  val ipv4 : Ipaddr.V4.t converter
  val ipv6 : Ipaddr.V6.t converter
  val ipv6_prefix : Ipaddr.V6.Prefix.t converter

end

include Functoria.KEY with module Arg := Arg

(** {2 Mirage keys} *)

val target: [ `Unix | `Xen | `MacOSX ] key
(** [-t TARGET]: Key setting the configuration mode for the current project.
    Is either ["xen"], ["unix"] or ["macosx"].
*)

val pp_target: [ `Unix | `Xen | `MacOSX ] Fmt.t
(** Pretty printer for the mode. *)

val is_xen: bool value
(** Is true iff the {!target} keys takes the value [`Xen]. *)

val unix: bool key
(** [--unix]. Set {!target} to [`Unix]. *)

val xen: bool key
(** [--xen]. Set {!target} to [`Xen]. *)

val no_ocaml_check: bool key
(** [--no-ocaml-check]. Do not check the version of the compiler. *)

val warn_error: bool key
(** [--warn-error]. Enable {i -warn-error} for OCaml sources. Set to [false] by
    default, but might might enabled by default in later releases. *)

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

val kv_ro : ?group:string -> unit -> [ `Archive | `Crunch | `Fat ] key
(** The type of key value store.
    Is either ["fat"], ["archive"] or ["crunch"]. *)

(** {3 Stack keys} *)

val dhcp : ?group:string -> unit -> bool key
(** Enable dhcp. Is either [true] or [false]. *)

val net : ?group:string -> unit -> [ `Direct | `Socket ] key
(** The type of stack. Is either ["direct"] or ["socket"]. *)

(** {3 Network keys} *)

val network : ?group:string -> string -> string key
(** A network interface. *)

(** Ipv4 keys. *)
module V4 : sig
  open Ipaddr.V4

  val ip : ?group:string -> t -> t key
  (** An ip address. *)

  val netmask : ?group:string -> t -> t key
  (** A netmask. *)

  val gateways : ?group:string -> t list -> t list key
  (** A list of gateways. *)

  val socket : ?group:string -> t option -> t option key
  (** An address bound by a socket. Will be none if no address is provided. *)

  val interfaces : ?group:string -> t list -> t list key
  (** A list of interfaces bound by a socket. *)

end

(** Ipv6 keys. *)
module V6 : sig
  open Ipaddr.V6

  val ip : ?group:string -> t -> t key
  (** An ip address. *)

  val netmask : ?group:string -> Prefix.t list -> Prefix.t list key
  (** A list of netmasks. *)

  val gateways : ?group:string -> t list -> t list key
  (** A list of gateways. *)

end
