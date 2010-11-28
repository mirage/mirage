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

let data_concat ls = (String.concat "\000" ls) ^ "\000"
let queue_path ty (tid: int) (path: string) con =
	let data = data_concat [ path; ] in
	Xb.queue con (Xb.Packet.create tid 0 ty data)

(* operations *)
let directory tid path con = queue_path Xb.Op.Directory tid path con
let read tid path con = queue_path Xb.Op.Read tid path con

let getperms tid path con = queue_path Xb.Op.Getperms tid path con

let debug commands con =
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Debug (data_concat commands))

let watch path data con =
	let data = data_concat [ path; data; ] in
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Watch data)

let unwatch path data con =
	let data = data_concat [ path; data; ] in
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Unwatch data)

let transaction_start con =
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Transaction_start (data_concat []))

let transaction_end tid commit con =
	let data = data_concat [ (if commit then "T" else "F"); ] in
	Xb.queue con (Xb.Packet.create tid 0 Xb.Op.Transaction_end data)

let introduce domid mfn port con =
	let data = data_concat [ Printf.sprintf "%u" domid;
	                         Printf.sprintf "%nu" mfn;
	                         string_of_int port; ] in
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Introduce data)

let release domid con =
	let data = data_concat [ Printf.sprintf "%u" domid; ] in
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Release data)

let resume domid con =
	let data = data_concat [ Printf.sprintf "%u" domid; ] in
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Resume data)

let getdomainpath domid con =
	let data = data_concat [ Printf.sprintf "%u" domid; ] in
	Xb.queue con (Xb.Packet.create 0 0 Xb.Op.Getdomainpath data)

let write tid path value con =
	let data = path ^ "\000" ^ value (* no NULL at the end *) in
	Xb.queue con (Xb.Packet.create tid 0 Xb.Op.Write data)

let mkdir tid path con = queue_path Xb.Op.Mkdir tid path con
let rm tid path con = queue_path Xb.Op.Rm tid path con

let setperms tid path perms con =
	let data = data_concat [ path; perms ] in
	Xb.queue con (Xb.Packet.create tid 0 Xb.Op.Setperms data)
