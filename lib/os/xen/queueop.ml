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

let next_rid =
    let last_rid = ref 0 in
    fun () ->
        let result = !last_rid in
        incr last_rid;
        result

let data_concat ls = (String.concat "\000" ls) ^ "\000"
let with_path ty (tid: int) (path: string) =
	let data = data_concat [ path; ] in
	Xb.Packet.create tid (next_rid ()) ty data

(* operations *)
let directory tid path = with_path Xb.Op.Directory tid path
let read tid path = with_path Xb.Op.Read tid path

let getperms tid path = with_path Xb.Op.Getperms tid path

let debug commands =
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Debug (data_concat commands)

let watch path data =
	let data = data_concat [ path; data; ] in
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Watch data

let unwatch path data =
	let data = data_concat [ path; data; ] in
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Unwatch data

let transaction_start =
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Transaction_start (data_concat [])

let transaction_end tid commit =
	let data = data_concat [ (if commit then "T" else "F"); ] in
	Xb.Packet.create tid (next_rid ()) Xb.Op.Transaction_end data

let introduce domid mfn port =
	let data = data_concat [ Printf.sprintf "%u" domid;
	                         Printf.sprintf "%nu" mfn;
	                         string_of_int port; ] in
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Introduce data

let release domid =
	let data = data_concat [ Printf.sprintf "%u" domid; ] in
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Release data

let resume domid =
	let data = data_concat [ Printf.sprintf "%u" domid; ] in
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Resume data

let getdomainpath domid =
	let data = data_concat [ Printf.sprintf "%u" domid; ] in
	Xb.Packet.create 0 (next_rid ()) Xb.Op.Getdomainpath data

let write tid path value =
	let data = path ^ "\000" ^ value (* no NULL at the end *) in
	Xb.Packet.create tid (next_rid ()) Xb.Op.Write data

let mkdir tid path = with_path Xb.Op.Mkdir tid path
let rm tid path = with_path Xb.Op.Rm tid path

let setperms tid path perms =
	let data = data_concat [ path; perms ] in
	Xb.Packet.create tid (next_rid ()) Xb.Op.Setperms data
