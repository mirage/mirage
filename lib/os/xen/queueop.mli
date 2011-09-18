(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *)

type token
(** A token is associated with every watch and returned in the callback *)

val token_to_string: token -> string
(** [token_to_string token] returns a debug-printable version of [token] *)

val create_token: string -> token
(** [create_token x] transforms [x] into a fresh watch token *)

val user_string_of_token: token -> string
(** [user_string_of_token token] returns the user-supplied part of [token] *)

val parse_token: string -> token
(** [parse_token x] parses the marshalled token [x] *)

val data_concat : string list -> string
val with_path : Xb_op.operation -> int -> string -> Xs_packet.t
val directory : int -> string -> Xs_packet.t
val read : int -> string -> Xs_packet.t
val getperms : int -> string -> Xs_packet.t
val debug : string list -> Xs_packet.t
val watch : string -> token -> Xs_packet.t
val unwatch : string -> token -> Xs_packet.t
val transaction_start : Xs_packet.t
val transaction_end : int -> bool -> Xs_packet.t
val introduce : int -> nativeint -> int -> Xs_packet.t
val release : int -> Xs_packet.t
val resume : int -> Xs_packet.t
val getdomainpath : int -> Xs_packet.t
val write : int -> string -> string -> Xs_packet.t
val mkdir : int -> string -> Xs_packet.t
val rm : int -> string -> Xs_packet.t
val setperms : int -> string -> string -> Xs_packet.t
