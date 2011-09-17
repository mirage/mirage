(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
 * Copyright (C) 2010 Anil Madhavapeddy <anil@recoil.org>
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

exception Timeout

(** perms contains 3 things:
    - owner domid.
    - other perm: applied to domain that is not owner or in ACL.
    - ACL: list of per-domain permission
  *)
type perms = Xsraw.perms

type domid = int
type con

type xsh = {
	con : con;
	debug: string list -> string Lwt.t;
	directory : string -> string list Lwt.t;
	read : string -> string Lwt.t;
	readv : string -> string list -> string list Lwt.t;
	write : string -> string -> unit Lwt.t;
	writev : string -> (string * string) list -> unit Lwt.t;
	mkdir : string -> unit Lwt.t;
	rm : string -> unit Lwt.t;
	getperms : string -> perms Lwt.t;
	setperms : string -> perms -> unit Lwt.t;
	setpermsv : string -> string list -> perms -> unit Lwt.t;
	introduce : domid -> nativeint -> int -> unit Lwt.t;
	release : domid -> unit Lwt.t;
	resume : domid -> unit Lwt.t;
	getdomainpath : domid -> string Lwt.t;
	watch : string -> string -> int Lwt.t;
	unwatch : string -> string -> unit Lwt.t;
}

(** get operations provide a vector of xenstore function that apply to one
    connection *)
val get_operations : con -> xsh

(** create a transaction with a vector of function that can be applied
    into the transaction. *)
val transaction : xsh -> (Xst.ops -> 'a Lwt.t) -> 'a Lwt.t

(** register a set of watches, then wait for watchevent.
    remove all watches previously set before giving back the hand. *)
val monitor_path : xsh
                 -> (string * string)
                 -> float
                 -> (string * string -> bool Lwt.t)
                 -> unit Lwt.t

val t : xsh
