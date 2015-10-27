(*
 * Copyright (c) 2014 David Sheets <sheets@alum.mit.edu>
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

(** Mirage run-time utilities *)

(** {2 Friendly run-time errors} *)
val string_of_network_init_error:
  string -> [> `Unknown of string | `Unimplemented | `Disconnected ] -> string
(** [string_of_network_init_error ifname] will generate a helpful string for
    network interface errors from the [ifname] interface name and the error
    constructor. *)

module Converter : sig
  include module type of Functoria_runtime.Converter

  val make : (string -> 'a option) -> 'a Fmt.t -> 'a desc
  (** [make of_string pp] creates a converter based on [of_string] and [pp]. *)

  module type S = sig
    type t
    val of_string : string -> t option
    val pp_hum : Format.formatter -> t -> unit
  end
  (** The signature used by {!of_module} to create a converter. *)

  val of_module : (module S with type t = 'a) -> 'a desc
  (** [of module (module M)] creates a converter out of
      a module answering the signature {!S}. *)

  (** {2 Usual mirage converters} *)

  val ip : Ipaddr.t desc
  val ipv4 : Ipaddr.V4.t desc
  val ipv6 : Ipaddr.V6.t desc
  val ipv6_prefix : Ipaddr.V6.Prefix.t desc

end


include module type of Functoria_runtime
  with module Converter := Converter
