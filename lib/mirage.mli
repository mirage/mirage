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

type mode = [
  | `Unix of [ `Direct | `Socket ]
  | `Xen
]
(** Usage modes. *)

type main_ml
(** Type of the [main.ml] file. *)

module type CONFIGURABLE = sig

  (** Configuration values. *)

  type t
  (** Type of configuration values to init that device. *)

  val name: t -> string
  (** Unique device name. *)

  val packages: t -> mode -> string list
  (** List of OPAM packages to install for this device. *)

  val libraries: t -> mode -> string list
  (** List of ocamlfind libraries. *)

  val configure: t -> mode -> main_ml -> unit
  (** Generate some code to create a value with the right
      configuration settings. This function appends some code in the
      provided out channel but it can also do stuff in the background
      (like calling 'mir-crunch' to generate static filesystems. *)

  val clean: t -> unit
  (** Remove all the autogen files. *)

end

module Io_page: sig

  (** Memory allocation interface. *)

  type t = unit

  include CONFIGURABLE with type t := t

end

module Clock: sig

  (** Clock operations. *)

  type t = unit

  include CONFIGURABLE with type t := t

end

module KV_RO: sig

  (** Static key/value pairs. *)

  type t = {
    name   : string;
    dirname: string;
  }
  (** Type for static key/value pairs configurations. *)

  include CONFIGURABLE with type t := t

end

module Console: sig

  (** Text console for input/ouput operations. *)

  type t = unit

  include CONFIGURABLE with type t := t

end

module Block: sig

  (** Block devices for filenames. *)

  type t = {
    name     : string;
    filename : string;
    read_only: bool; (** XXX: unused *)
  }
  (** Type for block device configuration. *)

  include CONFIGURABLE with type t := t

end

module Fat: sig

  (** FAT filesystem *)

  type t = {
    name : string;
    block: Block.t;
  }
  (** Type for a FAT filesystem configuration. *)

  include CONFIGURABLE with type t := t

end

(** {2 Network configuration} *)

module Network: sig

  (** Network interface. *)

  type t = Tap0 | Custom of string
  (** On OSX, it's either tap0 (default) or tap1, or linux it's the
      either tap0 or first available if nothing is specified with the
      custom variant. *)

  include CONFIGURABLE with type t := t

end

module IP: sig

  (** IP settings. *)

  type ipv4 = {
    address: Ipaddr.V4.t;
    netmask: Ipaddr.V4.t;
    gateway: Ipaddr.V4.t list;
  }
  (** Types for IPv4 manual configuration. *)

  type config =
    | DHCP
    | IPv4 of ipv4
  (** Type for configuring the IP adress. *)

  type t = {
    name    : string;
    config  : config;
    networks: Network.t list;
  }
  (** Main IP configuration. *)

  include CONFIGURABLE with type t := t

  val local: Network.t -> t
  (** Default local IP listening on the given network interface:
        - address: 10.0.0.2
        - netmask: 255.255.255.0
        - gateway: 10.0.0.1 *)

end

module HTTP: sig

  (** HTTP callbacks *)

  type t = {
    port   : int;
    address: Ipaddr.V4.t option;
    ip     : IP.t;
  }

  include CONFIGURABLE with type t := t

end

module Driver: sig

  (** All possible device configuration. *)

  type t =
    | Io_page of Io_page.t
    | Console of Console.t
    | Clock of Clock.t
    | Network of Network.t
    | KV_RO of KV_RO.t
    | Block of Block.t
    | Fat of Fat.t
    | IP of IP.t
    | HTTP of HTTP.t

  include CONFIGURABLE with type t := t

  val io_page: t
  (** Default io_page driver. *)

  val console: t
  (** Default console driver. *)

  val clock: t
  (** Default clock driver. *)

  val tap0: t
  (** Default network driver. *)

 val local_ip: Network.t -> t
  (** See [IP.local] *)

end

module Job: sig

(** Single jobs. *)

  type t = {
    name     : string;
    handler  : string;
    params   : Driver.t list;
  }
  (** Type for single job: the name of the main function and the list
      of devices it needs. *)

  val register: (string * Driver.t list) list -> unit
  (** Register a job list. *)

  include CONFIGURABLE with type t := t

end

type t = {
  name: string;
  root: string;
  jobs: Job.t list;
}
(** The collection of single jobs forms the main function. *)

val main_ml: t -> main_ml
(** Create an empty main_ml. *)

val load: string option -> t
(** Read a config file. If no name is given, use [config.ml]. *)

val manage_opam_packages: bool -> unit
(** Tell Irminsule to manage the OPAM configuration. *)

val add_to_opam_packages: string list -> unit
(** Add some base OPAM package to install *)

val add_to_ocamlfind_libraries: string list -> unit
(** Link with the provided additional libraries. *)

include CONFIGURABLE with type t := t

val build: t -> unit
(** Call [make build] in the right directory. *)

val run: t -> unit
(** call [make run] in the right directory. *)
