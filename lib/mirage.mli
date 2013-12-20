(*
 * Copyright (c) 2013 Thomas Gazagnaire <thomas@gazagnaire.org>
 * Copyright (c) 2013 Anil Madhavapeddy <anil@recoil.org>
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

(** Configuration library.

    [Mirage_types] defines a set of well-defined module signatures
    which are used by the various mirage libraries to implement a
    large collection of devicces. *)

(** {1 Values representing Mirage device configurations and jobs} *)

type 'a device
(** Device configuration value. *)

type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]
(** Usage modes. *)

(** {2 Device combinators} *)

type 'a fn
(** The type of values representing device functors. *)

val (-@>): 'a device -> 'b fn -> ('a -> 'b) fn
(** Construct a functor type from a type and an existing functor
    type. This corresponds to prepending a parameter to the list of
    functor parameters. For example,

    {| kv_ro @-> ip @-> returning kv_ro |}

    describes a functor type that accepts two arguments -- a kv_ro and
    an ip device -- and returns a kv_ro.
*)

val returning : 'a device -> 'a fn
(** Give the return type of a functor. Note that returning is intended
    to be used together with Mirage.(@->); see the documentation for
    Mirage.(@->) for an example. *)

(** {2 Page-aligned allocations} *)

type io_page
(** Abstract type for p-aligned allocation. *)

val io_page: io_page device
(** Default IO page allocator. *)

(** {2 Clocks} *)

type clock
(** Abstract type for clocks. *)

val clock: clock device
(** Default clock. *)

(** {2 Consoles} *)

type console
(** Abstract type for consoles. *)

val console: console device
(** Default console. *)

(** {2 Filesystem configurations} *)

type kv_ro
(** Abstract type for read-only key/value store. *)

type block
(** Abstract type for raw block devices. *)

type fs
(** Abstract type for filesystems. *)

val crunch: string -> kv_ro device
(** Crunch a directory. *)

val direct_ro: string -> kv_ro device
(** Direct access to the underlying filesystem as a key/value
    store. *)

val file: string -> block device
(** Use the given filen as a raw block device. *)

val fat: block device -> fs device
(** Consider a raw block device as a FAT filesystem. *)

val fat_kv_ro: block device -> kv_ro device
(** Consider a raw block device as a read-only FAT filesystem. *)

(** {2 Network interfaces} *)

type network
(** Abstract type for network configurations. *)

val tap0: network device
(** The '/dev/tap0' interface. *)

val network: string -> network device
(** A custom network interface. *)

(** {2 IP configuration} *)

type ip
(** Abstract type for IP configurations. *)

type ipv4 = {
  address: Ipaddr.V4.t;
  netmask: Ipaddr.V4.t;
  gateway: Ipaddr.V4.t list;
}
(** Types for IPv4 manual configuration. *)

val ipv4: ipv4 -> network device list -> ip device
(** Use an IPv4 address. *)

val default_ip: network device -> ip device
(** Default local IP listening on the given network interface:
    - address: 10.0.0.2
    - netmask: 255.255.255.0
    - gateway: 10.0.0.1 *)

val dhcp: network device list -> ip device
(** Use DHCP. *)

(** {2 HTTP configuration} *)

type http
(** Abstract type for http configurations. *)

val http: int -> ip device -> http device
(** Serve on the given port, with the given IP configuration. *)

(** {2 Jobs} *)

type job
(** Type for job values. *)

val job: string -> ('a -> 'b) fn -> job
(** Abstract type for jobs, taking [`a] as device configurations. *)

type t = {
  root: string;
  jobs: job list;
}
(** Type for values representing a project description. *)

val load: string option -> t
(** Read a config file. If no name is given, use [config.ml]. *)

(** {2 Device configuration} *)

module Device: sig

  (** Configurable device. *)

  val name: 'a device -> string
  (** Unique name. *)

  val packages: 'a device -> mode -> string list
  (** List of OPAM packages to install for this device. *)

  val libraries: 'a device -> mode -> string list
  (** List of ocamlfind libraries. *)

  val configure: 'a device -> mode -> unit
  (** Generate some code to create a value with the right
      configuration settings. *)

  val clean: 'a device -> unit
  (** Remove all the autogen files. *)

end

(** {2 Project configuration} *)

val manage_opam_packages: bool -> unit
(** Tell Irminsule to manage the OPAM configuration
    (ie. install/remove missing packages). *)

val add_to_opam_packages: string list -> unit
(** Add some base OPAM package to install *)

val add_to_ocamlfind_libraries: string list -> unit
(** Link with the provided additional libraries. *)

val packages: t -> mode -> string list
(** List of OPAM packages to install for this project. *)

val libraries: t -> mode -> string list
(** List of ocamlfind libraries. *)

val configure: t -> mode -> unit
(** Generate some code to create a value with the right
    configuration settings. *)

val clean: t -> unit
(** Remove all the autogen files. *)

val build: t -> unit
(** Call [make build] in the right directory. *)

val run: t -> unit
(** call [make run] in the right directory. *)
