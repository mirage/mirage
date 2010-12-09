
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

(** Common functionalities shared by other OCaml HTTP modules *)

open Types;;

  (** whether debugging messages are enabled or not, can be changed at runtime
  *)
val debug: bool ref

  (** print a string on stderr only if debugging is enabled *)
val debug_print: string -> unit

  (** pretty print an HTTP version *)
val string_of_version: version -> string

  (** parse an HTTP version from a string
  @raise Invalid_HTTP_version if given string doesn't represent a supported HTTP
  version *)
val version_of_string: string -> version

  (** pretty print an HTTP method *)
val string_of_method: meth -> string

  (** parse an HTTP method from a string
  @raise Invalid_HTTP_method if given string doesn't represent a supported
  method *)
val method_of_string: string -> meth

  (** converts an integer HTTP status to the corresponding status value
  @raise Invalid_code if given integer isn't a valid HTTP status code *)
val status_of_code: int -> status

  (** converts an HTTP status to the corresponding integer value *)
val code_of_status: [< status] -> int

  (** @return true on "informational" status codes, false elsewhere *)
val is_informational: int -> bool

  (** @return true on "success" status codes, false elsewhere *)
val is_success: int -> bool

  (** @return true on "redirection" status codes, false elsewhere *)
val is_redirection: int -> bool

  (** @return true on "client error" status codes, false elsewhere *)
val is_client_error: int -> bool

  (** @return true on "server error" status codes, false elsewhere *)
val is_server_error: int -> bool

  (** @return true on "client error" and "server error" status code, false
  elsewhere *)
val is_error: int -> bool

