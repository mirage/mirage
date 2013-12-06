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

val main_ml: t -> main_ml
(** Create an empty main_ml. *)

val load: string option -> t
(** Read a config file. If no name is given, use [config.ml]. *)

val manage_opam_packages: bool -> unit
(** Tell Irminsule to manage the OPAM configuration. *)

include CONFIGURABLE with type t := t

val run: t -> mode:mode -> unit
(** [run ~mode conf_file] runs a project. If [conf_file] is [None],
    then look for a `.conf` file in the current directory. *)

module V1: sig

  (** Useful specialisation for some Mirage types. *)

  exception Driver_initialisation_error of string
  (** Driver initialisation error *)

  open V1

  module type KV_RO = KV_RO
    with type id = unit
     and type 'a io = 'a Lwt.t
     and type page_aligned_stream = Cstruct.t Lwt_stream.t
    (** KV RO *)

  module type CONSOLE = CONSOLE
    with type 'a io = 'a Lwt.t
    (** Consoles *)

end
