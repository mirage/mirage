
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

(** Sanity test functions related to HTTP message parsing *)

  (** @param name an HTTP header name
  @raise Invalid_header_name if name isn't a valid HTTP header name *)
val heal_header_name: string -> unit

  (** @param value an HTTP header value
  @raise Invalid_header_value if value isn't a valid HTTP header value *)
val heal_header_value: string -> unit

  (** @param header a pair header_name * header_value
  @raise Invalid_header_name if name isn't a valid HTTP header name
  @raise Invalid_header_value if value isn't a valid HTTP header value *)
val heal_header: string * string -> unit

  (** remove heading and/or trailing LWS sequences as per RFC2616 *)
val normalize_header_value: string -> string

