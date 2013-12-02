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

type document
(** Type of documents. *)

val empty: string -> document
(** Empty document. *)

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

  val prepare: t -> mode -> unit
  (** Prepare the device configuration by calling some external
      command (as mi-crunch). The package containing these external
      tools should appear in the [packages] list above. *)

  val output: t -> mode -> document -> unit
  (** Generate some code to create a value with the right
      configuration settings. This function appends some code in the
      provided out channel but it can also do stuff in the background
      (like calling 'mir-crunch' to generate static filesystems. *)

end

module IO_page: sig

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

module FAT: sig

  (** FAT *)

  type t = {
    name : string;
    block: Block.t;
  }
  (** Type for FAT configuration. *)

  include CONFIGURABLE with type t := t

end

(** {2 Network configuration} *)

module IP: sig

  (** IP settings. *)

  type ipv4 = {
    address: Ipaddr.V4.t;
    netmask: Ipaddr.V4.t;
    gateway: Ipaddr.V4.t list;
  }
  (** Types for IPv4 configuration. *)

  type conf =
    | DHCP
    | IPv4 of ipv4
  (** Type for configuring the IP adress. *)

  type t = {
    name: string;
    conf: conf;
  }
  (** Main IP configuration. *)

  include CONFIGURABLE with type t := t

end

module HTTP: sig

  (** HTTP settings. *)

  type t = {
    port   : int;
    address: Ipaddr.V4.t option;
    static : KV_RO.t option;
  }
  (** Type for HTTP configuration. *)

  include CONFIGURABLE with type t := t

end

module Driver: sig

  (** All possible device configuration. *)

  type t =
    | IO_page of IO_page.t
    | Console of Console.t
    | Clock of Clock.t
    | KV_RO of KV_RO.t
    | Block of Block.t
    | FAT of FAT.t
    | IP of IP.t
    | HTTP of HTTP.t

  include CONFIGURABLE with type t := t

end

module Job: sig

(** Single jobs. *)

  type t = {
    name   : string;
    handler: string;
    params : Driver.t list;
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

include CONFIGURABLE with type t := t

val configure: t -> mode:mode -> install:bool -> unit
(** [configure ~mode ~install conf_file] configure a project. If
    [conf_file] is [None], then look for a `.conf` file in the current
    directory. *)

val run: t -> mode:mode -> unit
(** [run ~mode conf_file] runs a project. If [conf_file] is [None],
    then look for a `.conf` file in the current directory. *)

val load: string option -> t
(** Read a config file. If no name is given, use [config.ml]. *)
