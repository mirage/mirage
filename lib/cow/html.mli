(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.org>
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

type t = (('a Xml.frag as 'a) Xml.frag) list

val to_string : t -> string

val of_string :
  ?templates:( (string * t) list ) ->
  ?enc:Xml.encoding ->
  string -> t

(** {2 HTML library} *)

type link = {
  text : string;
  href: string;
}

val html_of_link : link -> t

val interleave : string array -> t list -> t list

val html_of_string : string -> t
val html_of_int : int -> t
val html_of_float : float -> t

type table = t array array

val html_of_table : ?headings:bool -> table -> t

val nil : t
