
(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Library General Public License as
  published by the Free Software Foundation, version 2.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
  USA
*)

(** Helpers and other not better classified functions which should not be
exposed in the final API *)

  (** @return the current date compliant to RFC 1123, which updates RFC 822
  zone info are retrieved from UTC *)
val date_822: unit -> string

(** Convert a number of seconds to a date compliant with RFC 822 *)
val rfc822_of_float : float -> string

  (** strip trailing '/', if any, from a string and @return the new string *)
val strip_trailing_slash: string -> string

  (** strip heading '/', if any, from a string and @return the new string *)
val strip_heading_slash: string -> string

  (** explode a string in a char list *)
val string_explode: string -> char list

  (** implode a char list in a string *)
val string_implode: char list -> string

  (** given an HTTP response code return the corresponding reason phrase *)
val reason_phrase_of_code: int -> string

  (** like List.assoc but return all bindings of a given key instead of the
  leftmost one only *)
val list_assoc_all: 'a -> ('a * 'b) list -> 'b list

val warn: string -> unit (** print a warning msg to stderr. Adds trailing \n *)
val error: string -> unit (** print an error msg to stderr. Adds trailing \n *)

