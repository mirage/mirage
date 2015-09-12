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

open Rresult

(** Utility module. *)

exception Fatal of string

(** {2 Misc} *)

val (@?) : 'a option -> 'a list -> 'a list
(** [x @? l] cons the content of [x] to [l] is it exists. *)

val opt_map : ('a -> 'b) -> 'a option -> 'b option

val generated_header: unit -> string
(** [generated_header ()] is the header string for
    every generated file. [appname] is the name given by {!get_section}. *)

val ocaml_version: unit -> int * int
(** The version of the current OCaml compiler. *)

val (/): string -> string -> string
(** Same as [Filename.concat]. *)

val err_cmdliner :
  ?usage:bool -> ('a, string) result -> 'a Cmdliner.Term.ret

module type Monoid = sig
  type t
  val empty : t
  val union : t -> t -> t
end

(** {2 String utilities} *)

module StringSet : Set.S with type elt = string

val strip: string -> string
(** Remove heading and trailing spaces. *)

val cut_at: string -> char -> (string * string) option
(** Cut at the first occurence of a given character. *)

val split : string -> char -> string list
(** Split at each occurence of the given character. *)

val prefix : string -> by:string -> string
(** [prefix x ~by:s] will prefix [x] by [s] if [s] is not the empty string. *)

val suffix : string -> by:string -> string
(** Similar to {!prefix} but suffix. *)

(** {2 Command-line utilities} *)

val command_exists: string -> bool

val command:
  ?redirect:bool -> ('a, unit, string, (unit, string) result) format4 -> 'a

val read_command: ('a, unit, string,  (string, string) result) format4 -> 'a

val remove: string -> unit

val realpath: string -> string

val with_channel : out_channel -> (Format.formatter -> unit) -> unit
val with_file : string -> (Format.formatter -> unit) -> unit

val with_process_in : string -> (in_channel -> 'a) -> 'a
val with_process_out : string -> (out_channel -> 'a) -> 'a

val opam:
  string -> ?yes:bool -> ?switch:string -> string list -> (unit, string) result

val in_dir: string -> (unit -> 'a) -> 'a

val uname_s: unit -> string option
val uname_m: unit -> string option
val uname_r: unit -> string option

module OCamlfind : sig
  val query : ?predicates:string list -> ?format:string -> ?recursive:bool -> string list -> (string list, string) result
  val installed : string -> bool
end

(** {2 Display} *)

val set_section: string -> unit

val get_section: unit -> string

val error :
  ('a, Format.formatter, unit, ('b, string) result) format4 -> 'a

val fail: ('a, Format.formatter, unit, 'b) format4 -> 'a

val info: ('a, Format.formatter, unit, unit) format4 -> 'a

val debug: ('a, Format.formatter, unit, unit) format4 -> 'a

val blue  : string Fmt.t
val yellow: string Fmt.t
val red   : string Fmt.t
val green : string Fmt.t

(** Generation of fresh names *)
module Name: sig

  val create: string -> string
  (** [create base] creates a fresh name using the given [base]. *)

  val of_key: string -> base:string -> string
  (** [find_or_create key base] returns a unique name corresponding to
      the key. *)

end


module Codegen: sig

  val append: Format.formatter -> ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a

  val newline: Format.formatter -> unit

  val set_main_ml: string -> unit
  (** Define the current main file. *)

  val append_main: ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a
  (** Add some string to [main.ml]. *)

  val newline_main: unit -> unit
  (** Add a newline to [main.ml]. *)

end


(** TTY feature detection *)
module Terminfo: sig
  val columns : unit -> int
end
