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

type pkt =
{
	tid: int;
	rid: int;
	ty: Xb_op.operation;
	len: int;
	buf: Buffer.t;
}

external header_size: unit -> int = "stub_header_size"
external header_of_string_internal: string -> int * int * int * int
         = "stub_header_of_string"

let of_string s =
	let tid, rid, opint, dlen = header_of_string_internal s in
	{
		tid = tid;
		rid = rid;
		ty = (Xb_op.of_cval opint);
		len = dlen;
		buf = Buffer.create dlen;
	}

let append pkt s sz =
	Buffer.add_string pkt.buf (String.sub s 0 sz)

let to_complete pkt =
	pkt.len - (Buffer.length pkt.buf)
