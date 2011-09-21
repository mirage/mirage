(*
 * Copyright (c) 2011 Citrix Systems
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

module Path : sig
  type t
  val of_string_list: string list -> t
  val to_string_list: t -> string list
  val directory: t -> t
  val filename: t -> string
  val to_string: t -> string
  val of_string: string -> t
  val cd: t -> string -> t
  val is_root: t -> bool
end

module Dir_entry : sig

  type datetime = {
    year: int;
    month: int;
    day: int;
    hours: int;
    mins: int;
    secs: int;
    ms: int;
  }

  type r

  val to_string: r -> string
end

type error =
  | Not_a_directory of Path.t
  | Is_a_directory of Path.t
  | Directory_not_empty of Path.t
  | No_directory_entry of Path.t * string
  | File_already_exists of string
  | No_space
type 'a result =
  | Error of error
  | Success of 'a

module Stat : sig
  type t = 
    | File of Dir_entry.r
    | Dir of Dir_entry.r * (Dir_entry.r list) (** the directory itself and its immediate children *)
end

module type FS = sig
  type fs
  val make: unit -> fs Lwt.t

  type file

  val create: fs -> Path.t -> unit result Lwt.t

  val mkdir: fs -> Path.t -> unit result Lwt.t

  (** [destroy fs path] removes a [path] on filesystem [fs] *)
  val destroy: fs -> Path.t -> unit result Lwt.t

  (** [file_of_path fs path] returns a [file] corresponding to [path] on
      filesystem [fs] *)
  val file_of_path: fs -> Path.t -> file

  (** [stat fs f] returns information about file [f] on filesystem [fs] *)
  val stat: fs -> Path.t -> Stat.t result Lwt.t

  (** [write fs f offset bs] writes bitstring [bs] at [offset] in file [f] on
      filesystem [fs] *)
  val write: fs -> file -> int -> Bitstring.t -> unit result Lwt.t

  (** [read fs f offset length] reads up to [length] bytes from file [f] on
      filesystem [fs]. If less data is returned than requested, this indicates
      end-of-file. *)
  val read: fs -> file -> int -> int -> Bitstring.t result Lwt.t
end

module type BLOCK = sig
  val read_sector: int -> Bitstring.t Lwt.t
  val write_sector: int -> Bitstring.t -> unit Lwt.t
end

module FATFilesystem : functor(B: BLOCK) -> FS

val make_kvro: id:string -> vbd:OS.Devices.blkif -> OS.Devices.kv_ro Lwt.t

