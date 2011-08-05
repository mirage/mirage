(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
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

(** URL type *)
type t = {
  scheme       : string option;
  userinfo     : string option;
  host         : string;
  port         : int option;
  path         : string list option;
  path_string  : string option;
  query        : (string * string) list option;
  query_string : string option;
  fragment     : string option;
}

(** Get the full path of an url (ie. including leading /, queries and fragments *)
val full_path : t -> string

(** Build an encoded string from an URL *)
val to_string : t -> string

(** Build an URL from an encoded string *)
val of_string : string -> t

(** URL encode the string *)
val encode : string -> string

(** URL decode the string *)
val decode : string -> string
