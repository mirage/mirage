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

open Rresult

val (/): string -> string -> string
(** Same as [Filename.concat]. *)

val err_cmdliner: ?usage:bool -> ('a, string) result -> 'a Cmdliner.Term.ret

module type Monoid = sig
  type t
  val empty: t
  val union: t -> t -> t
end

module Set: sig
  (** Compat with OCaml < 4.02 *)
  module type S = sig
    include Set.S
    val of_list: elt list -> t
  end
  module Make (M:Set.OrderedType): S with type elt = M.t
end

(** {2 String utilities} *)

module String: sig
  include (module type of String)

  module Set: Set.S with type elt = string

  val strip: string -> string
  (** Remove heading and trailing spaces. *)

  val cut_at: string -> char -> (string * string) option
  (** Cut at the first occurrence of a given character. *)

  val split: string -> char -> string list
  (** Split at each occurence of the given character. *)
end

(** {2 Command-line utilities} *)

module Cmd: sig
  val exists: string -> bool
  val run:
  ?redirect:bool -> ('a, unit, string, (unit, string) result) format4 -> 'a
  val read: ('a, unit, string,  (string, string) result) format4 -> 'a
  val remove: string -> unit
  val realpath: string -> string
  val with_channel: out_channel -> (Format.formatter -> 'a) -> 'a
  val with_file: string -> (Format.formatter -> 'a) -> 'a
  val with_process_in: string -> (in_channel -> 'a) -> 'a
  val with_process_out: string -> (out_channel -> 'a) -> 'a
  val opam:
    string -> ?yes:bool -> ?switch:string -> ?color:Fmt.style_renderer ->
    string list -> (unit, string) result
  val in_dir: string -> (unit -> 'a) -> 'a
  val uname_s: unit -> string option
  val uname_m: unit -> string option
  val uname_r: unit -> string option
  val ocaml_version: unit -> int * int

  module OCamlfind: sig
    val query:
      ?predicates:string list -> ?format:string -> ?recursive:bool ->
      string list -> (string list, string) result
    val installed: string -> bool
  end

end


(** {2 Display} *)

module Log: sig
  type level = FATAL | ERROR | WARN | INFO | DEBUG
  val set_level: level -> unit
  val get_level: unit -> level
  val set_color: Fmt.style_renderer option -> unit
  val get_color: unit -> Fmt.style_renderer option
  val set_section: string -> unit
  val get_section: unit -> string
  val error:
    ('a, Format.formatter, unit, ('b, string) result) format4 -> 'a
  val fatal: ('a, Format.formatter, unit, 'b) format4 -> 'a
  val info: ('a, Format.formatter, unit) format -> 'a
  val debug: ('a, Format.formatter, unit) format -> 'a
  val show_error: ('a, Format.formatter, unit) format -> 'a
  val blue: string Fmt.t
  val yellow: string Fmt.t
  val red: string Fmt.t
  val green: string Fmt.t
end

(** Generation of fresh names *)
module Name: sig
  val ocamlify: string -> string
  val create: string -> prefix:string -> string
end

module Codegen: sig
  val generated_header: unit -> string
  val append: Format.formatter -> ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a
  val newline: Format.formatter -> unit
  val set_main_ml: string -> unit
  val append_main: ('a, Format.formatter, unit, unit, unit, unit) format6 -> 'a
  val newline_main: unit -> unit
end

(** TTY feature detection *)
module Terminfo: sig
  val columns: unit -> int
end

(** Universal map *)
module Univ: sig
  type 'a key
  val new_key: string -> 'a key
  type t
  val empty: t
  val add: 'a key -> 'a -> t -> t
  val mem: 'a key -> t -> bool
  val find: 'a key -> t -> 'a option
end
