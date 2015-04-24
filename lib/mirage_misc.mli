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

(** Utility module. *)

(** {2 Misc} *)

val generated_by_mirage: string
(** The header string for every generated file. *)

val ocaml_version: unit -> int * int
(** The version of the current OCaml compiler. *)

val (/): string -> string -> string
(** Same as [Filename.concat]. *)

(** {2 String utilities} *)

val strip: string -> string
(** Remove heading and trailing spaces. *)

val cut_at: string -> char -> (string * string) option
(** Cut at the first occurence of a given character. *)

val split : string -> char -> string list
(** Split at each occurence of the given character. *)

val after : string -> string -> string option
(** [after prefix s] returns the part of [s] after [prefix],
 * if [s] starts with [prefix]. *)

(** {2 Channels} *)

val append: out_channel -> ('a, unit, string, unit) format4 -> 'a

val newline: out_channel -> unit

(** {2 Command-line utilities} *)

val command_exists: string -> bool

val command: ?redirect:bool -> ('a, unit, string, unit) format4 -> 'a

val read_command: ('a, unit, string, string) format4 -> 'a

val remove: string -> unit

val realpath: string -> string

val opam: string -> ?yes:bool -> ?switch:string -> string list -> unit

val in_dir: string -> (unit -> 'a) -> 'a

val uname_s: unit -> string option
val uname_m: unit -> string option
val uname_r: unit -> string option

module OCamlfind : sig
  val query : ?predicates:string list -> ?format:string -> ?recursive:bool -> string list -> string list
end

(** {2 Display} *)

val set_section: string -> unit

val get_section: unit -> string

val error: ('a, unit, string, 'b) format4 -> 'a

val info: ('a, unit, string, unit) format4 -> 'a

val blue_s: string -> string

val yellow_s: string -> string

(** {2 Hash tables} *)

val cofind: ('a, 'b) Hashtbl.t -> 'b -> 'a
(** Can raise [Not_found]. *)

val find_or_create: ('a, 'b) Hashtbl.t -> 'a -> (unit -> 'b) -> 'b
(** Find the value associated with a key in an hash-table or create a
    new value if it the key is not already in there. *)

val dump: (string, string) Hashtbl.t -> unit
(** Dump the contents of a hash table to stderr. *)

val dedup: string list -> string list
(** Deduplicate the list elements. Return an ordered list. *)
