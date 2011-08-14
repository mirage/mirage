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
val queue_path : Xb_op.operation -> int -> string -> Xb.t -> unit
val directory : int -> string -> Xb.t -> unit
val read : int -> string -> Xb.t -> unit
val getperms : int -> string -> Xb.t -> unit
val debug : string list -> Xb.t -> unit
val watch : string -> string -> Xb.t -> unit
val unwatch : string -> string -> Xb.t -> unit
val transaction_start : Xb.t -> unit
val transaction_end : int -> bool -> Xb.t -> unit
val introduce : int -> nativeint -> int -> Xb.t -> unit
val release : int -> Xb.t -> unit
val resume : int -> Xb.t -> unit
val getdomainpath : int -> Xb.t -> unit
val write : int -> string -> string -> Xb.t -> unit
val mkdir : int -> string -> Xb.t -> unit
val rm : int -> string -> Xb.t -> unit
val setperms : int -> string -> string -> Xb.t -> unit
