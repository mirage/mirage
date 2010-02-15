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
type t =
{
	tid: int;
	rid: int;
	ty: Xb_op.operation;
	data: string;
}

exception Error of string
exception DataError of string

external string_of_header: int -> int -> int -> int -> string = "stub_string_of_header"

let create tid rid ty data = { tid = tid; rid = rid; ty = ty; data = data; }

let of_partialpkt ppkt =
	create ppkt.Xb_partial.tid ppkt.Xb_partial.rid ppkt.Xb_partial.ty (Buffer.contents ppkt.Xb_partial.buf)

let to_string pkt =
	let header = string_of_header pkt.tid pkt.rid (Xb_op.to_cval pkt.ty) (String.length pkt.data) in
	header ^ pkt.data

let unpack pkt =
	pkt.tid, pkt.rid, pkt.ty, pkt.data

let get_tid pkt = pkt.tid
let get_ty pkt = pkt.ty
let get_data pkt =
	let l = String.length pkt.data in
	if l > 0 && pkt.data.[l - 1] = '\000' then
		String.sub pkt.data 0 (l - 1)
	else
		pkt.data
let get_rid pkt = pkt.rid
