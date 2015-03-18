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

module Configvar : sig
  type 'a desc

  val string : string desc
  val ipaddrv4 : Ipaddr.V4.t desc
  val ipaddrv6 : Ipaddr.V6.t desc
  val ipaddrprefixv6 : Ipaddr.V6.Prefix.t desc
  val list : 'a desc -> 'a list desc
  val dhcporstaticv4 : [ `DHCP | `IPv4 of Ipaddr.V4.t * Ipaddr.V4.t * Ipaddr.V4.t list ] desc

  val print_meta : unit -> 'a desc -> string
  val print_ocaml : 'a desc -> unit -> 'a -> string
  val print_human : 'a desc -> unit -> 'a -> string
  val parse_human : 'a desc -> string -> 'a option

  module Cmdliner_aux : sig
    val converter : 'a desc -> 'a Cmdliner.Arg.converter
    val term : 'a desc -> 'a option ref -> doc:string -> name:string -> runtime:bool -> unit Cmdliner.Term.t
  end
end
