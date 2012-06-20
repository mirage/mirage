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

open Pervasives
type operation = Debug | Directory | Read | Getperms |
                 Watch | Unwatch | Transaction_start |
                 Transaction_end | Introduce | Release |
                 Getdomainpath | Write | Mkdir | Rm |
                 Setperms | Watchevent | Error | Isintroduced |
                 Resume | Set_target
               | Restrict 

(* There are two sets of XB operations: the one coming from open-source and *)
(* the one coming from our private patch queue. These operations            *)
(* in two differents arrays for make easier the forward compatibility       *)
let operation_c_mapping =
	[| Debug; Directory; Read; Getperms;
           Watch; Unwatch; Transaction_start;
           Transaction_end; Introduce; Release;
           Getdomainpath; Write; Mkdir; Rm;
           Setperms; Watchevent; Error; Isintroduced;
           Resume; Set_target |]
let size = Array.length operation_c_mapping

(* [offset_pq] has to be the same as in <xen/io/xs_wire.h> *)
external get_internal_offset: unit -> int = "stub_get_internal_offset"
let offset_pq = get_internal_offset ()

let operation_c_mapping_pq =
	[| Restrict |]
let size_pq = Array.length operation_c_mapping_pq

let array_search el a =
	let len = Array.length a in
	let rec search i =
		if i > len then raise Not_found;
		if a.(i) = el then i else search (i + 1) in
	search 0

let of_cval i =
	if i >= 0 && i < size
	then operation_c_mapping.(i)
	else if i >= offset_pq && i < offset_pq + size_pq
	then operation_c_mapping_pq.(i-offset_pq)
	else raise Not_found

let to_cval op =
	try
	array_search op operation_c_mapping
	with _ -> offset_pq + array_search op operation_c_mapping_pq

let to_string ty =
	match ty with
	| Debug			-> "DEBUG"
	| Directory		-> "DIRECTORY"
	| Read			-> "READ"
	| Getperms		-> "GET_PERMS"
	| Watch			-> "WATCH"
	| Unwatch		-> "UNWATCH"
	| Transaction_start	-> "TRANSACTION_START"
	| Transaction_end	-> "TRANSACTION_END"
	| Introduce		-> "INTRODUCE"
	| Release		-> "RELEASE"
	| Getdomainpath		-> "GET_DOMAIN_PATH"
	| Write			-> "WRITE"
	| Mkdir			-> "MKDIR"
	| Rm			-> "RM"
	| Setperms		-> "SET_PERMS"
	| Watchevent		-> "WATCH_EVENT"
	| Error			-> "ERROR"
	| Isintroduced		-> "IS_INTRODUCED"
	| Resume		-> "RESUME"
	| Set_target		-> "SET_TARGET"
	| Restrict		-> "RESTRICT"
