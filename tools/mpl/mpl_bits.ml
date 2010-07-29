(*
 * Copyright (c) 2005 Anil Madhavapeddy <anil@recoil.org>
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
 *
 * $Id: mpl_bits.ml,v 1.5 2005/12/05 00:46:06 avsm Exp $
 *)

open Printf
open Mpl_utils

type t = 
	|ShiftRight of (int * int)
	|MaskLeft of (int * int)
	|MergeAt of (int * int)
	|GrabByte of int

let dbg = prerr_endline
	
let dump_ops (ac,x) =
	dbg (sprintf "ac=%d" ac);
	List.iter (function
		|ShiftRight (loc,am) -> dbg (sprintf "ShiftRight (%d,%d)" loc am);
		|MaskLeft (loc,am) -> dbg (sprintf "MaskLeft (%d,%d)" loc am);
		|MergeAt (loc,am) -> dbg (sprintf "MergeAt (%d,%d)" loc am);
		|GrabByte loc -> dbg (sprintf "GrabByte (%d)" loc);
	) x

let bitbytes =
	List.fold_left (fun a -> function
		|GrabByte loc -> loc :: a
		|_ -> a
	) []

let bitvars l =
	list_unique (List.fold_left (fun a -> function
		|ShiftRight (loc,_) -> (loc:int) :: a
		|MaskLeft (loc,_) -> loc :: a
		|MergeAt _ -> a
		|GrabByte _ -> a
	) [] l)

let bitops =
	List.fold_left (fun a -> function
		|GrabByte x -> a
		|x -> x :: a
   ) []

let bitdeps varl ops =
	let d = ref [] in
	let base = (List.length varl) - (List.length (bitbytes ops) + 1) in
	for i = 0 to List.length varl - 1 do
		if i >= base then d := !d @ [(List.nth varl i)];
	done;
	!d

let to_expr varl ops =
	let base = (List.length varl) - (List.length (bitbytes ops) + 1) in
(*	dbg (sprintf "to_expr: varl=(%s) base=%d" (String.concat "," varl) base);
	dump_ops (0,ops); *)
	let es = ref [] in
	let addes x = es := x :: !es in
	let varnm loc = List.nth varl (base+loc) in
	let rec fn = function
	 |GrabByte p :: MergeAt (mgf,mgt) :: r ->
		assert(mgt==8);
		addes (sprintf "%s lsl %d" (varnm p) (mgf-mgt));
		fn r
	 |GrabByte p :: r -> fn r
	 |ShiftRight (srloc,sram) :: MaskLeft (mlloc,mlam) :: MergeAt (mgf,mgt) :: r ->
		assert (srloc = mlloc);
		addes (sprintf "((%s lsr %d) land %d) lsl %d" (varnm srloc) sram (tworaised mlam) (mgf-mgt));
		fn r
	 |ShiftRight (srloc,sram) :: MergeAt(mgf,mgt) :: r ->
		addes (sprintf "(%s lsr %d) lsl %d" (varnm srloc) sram (mgf-mgt));
		fn r
	 |MaskLeft (mlloc,mlam) :: MergeAt (mgf,mgt) :: r ->
		addes (sprintf "(%s land %d) lsl %d" (varnm mlloc) (tworaised mlam) (mgf-mgt));
		fn r
	 |[] -> ()
	 |_ -> failwith "bits:to_expr"
	in fn ops;
	String.concat " + " (List.map (fun x -> sprintf "(%s)" x) !es)

let convert ac sz =
	let bid = ref 0 in
   let nac = ref ac in
	let nbits = ref sz in
	let ops = ref [] in
	let aop x = ops := !ops @ [x] in
	let decrbits n =
		nbits := !nbits - n;
		nac := !nac + n;
	in
	(* first, align with a byte boundary *)	
	if ac <> 0 then begin
	   let toalign = min (8 - ac) !nbits in
		(* shift right enough to make into a 'number' *)
		let sr = 8 - (ac + toalign) in
		aop (ShiftRight (!bid,sr));
		(* mask the rest of the bit *)
		let ml = 8 - (ac + sr) in
		aop (MaskLeft (!bid,ml));
		aop (MergeAt (!nbits, toalign));
		decrbits toalign;
	end;
	(* iterate the rest out *)
	while !nbits > 7 do
		incr bid;
		aop (GrabByte (!bid));
		aop (MergeAt (!nbits, 8));
		decrbits 8;
	done;
	(* grab any remainder *)
	if !nbits > 0 then begin
		assert (!nbits < 8);
		incr bid;
		aop (GrabByte (!bid));
		let sr = 8 - !nbits in
		aop (ShiftRight (!bid,sr));
		aop (MergeAt (!nbits,!nbits));
		decrbits !nbits;
	end;
	assert (!nbits = 0);
	(!nac mod 8),!ops
	
let test () =
	let l = [(5,13);(0,13);(0,8);(1,7);(1,8);(1,3)] in
	List.iter (fun (a,b) ->
		prerr_endline (sprintf "from %d, length %d" a b);
		dump_ops (convert a b);
		prerr_endline "---";
	) l
