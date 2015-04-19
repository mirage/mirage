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
  (** Run-time support for setting configuration keys on the command-line. *)

  type 'a desc
  (** The type of type descriptors.  A value of tyep ['a desc] knows how to
      parse and print values of type ['a] and also how to print an OCaml
      representation of *itself*. *)

  val string : string desc
  (** Type descriptor for arbitrary strings. *)

  val ipaddrv4 : Ipaddr.V4.t desc
  (** Type desciptor for IPv4 addresses. *)

  val ipaddrv6 : Ipaddr.V6.t desc
  (** Type descriptor for IPv6 addresses. *)

  val ipaddrprefixv6 : Ipaddr.V6.Prefix.t desc
  (** Type descriptor for IPv6 prefixes. *)

  val list : 'a desc -> 'a list desc
  (** [list d] is a type descriptor for lists of values with type descriptor
      [d].  Its human-readable representation is a [',']-separated list of the
      representation of its values. *)

  val dhcporstaticv4 : [ `DHCP | `IPv4 of Ipaddr.V4.t * Ipaddr.V4.t * Ipaddr.V4.t list ] desc
  (** Type descriptor for values which describe a choice between DHCP and static
      IP configuration.  Its human representation is one of:

      - the string 'dhcp'

      - the string 'static:X:Y:Z,...', where [X] is the IPv4 address, [Y] is the
        IPv4 netmask, and [Z, ...] is a [',']-separated list of IPv4 gateway
        addresses. *)


  val print_meta : unit -> 'a desc -> string
  (** [print_meta () d] is a string [s] such that its contents evaluate to
      [d]. *)

  val print_ocaml : 'a desc -> unit -> 'a -> string
  (** [print_ocaml d () x] is a string [s] such that evaluating the contents of
      [s] gives [x]. *)

  val print_human : 'a desc -> unit -> 'a -> string
  (** [print_human d () x] is a string [s] giving a human-readable
      representation of [x]. *)

  val parse_human : 'a desc -> string -> 'a option
  (** [parse_human d s] parses a human-readable representation of [x] assuming
      that its type is described by [d].  The equation [parse_human d
      (print_human d () x) = Some x] should hold always. *)

  module Cmdliner_aux : sig
    (** Utilities to interface with [Cmdliner]. *)

    val converter : 'a desc -> 'a Cmdliner.Arg.converter
    (** [converter d] produces a [Cmdliner] converter from a type descriptor [d]. *)

    val term : 'a desc -> 'a option ref -> doc:string -> name:string -> runtime:bool -> unit Cmdliner.Term.t
    (** [term d r ~doc ~name ~runtime] is a [unit Cmdliner.Term.t] that, when
        evaluated, sets [r] with the value of the command-line argument
        corresponding to [name].  [runtime] should be [true] if this function is
        being called at run-time and [false] if it is being called at
        compile-time. *)
  end
end
