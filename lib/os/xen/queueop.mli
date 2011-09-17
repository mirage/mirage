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

val data_concat : string list -> string
val with_path : Xb_op.operation -> int -> string -> Xs_packet.t
val directory : int -> string -> Xs_packet.t
val read : int -> string -> Xs_packet.t
val getperms : int -> string -> Xs_packet.t
val debug : string list -> Xs_packet.t
val watch : string -> string -> Xs_packet.t
val unwatch : string -> string -> Xs_packet.t
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
