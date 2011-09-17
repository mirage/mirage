(* Bitstring syntax extension.
 * Copyright (C) 2008 Red Hat Inc., Richard W.M. Jones
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version,
 * with the OCaml linking exception described in COPYING.LIB.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 *
 * $Id: pa_bitstring.ml 179 2010-01-08 14:28:17Z richard.wm.jones $
 *)

open Printf

open Camlp4.PreCast
open Syntax
open Ast

open Bitstring_types
module P = Bitstring_persistent

(* If this is true then we emit some debugging code which can
 * be useful to tell what is happening during matches.  You
 * also need to do 'Bitstring.debug := true' in your main program.
 *
 * If this is false then no extra debugging code is emitted.
 *)
let debug = false

(* Hashtable storing named persistent patterns. *)
let pattern_hash : (string, P.pattern) Hashtbl.t = Hashtbl.create 13

let locfail _loc msg = Loc.raise _loc (Failure msg)

(* Work out if an expression is an integer constant.
 *
 * Returns [Some i] if so (where i is the integer value), else [None].
 *
 * Fairly simplistic algorithm: we can only detect simple constant
 * expressions such as [k], [k+c], [k-c] etc.
 *)
let rec expr_is_constant = function
  | <:expr< $int:i$ >> ->	       (* Literal integer constant. *)
    Some (int_of_string i)
  | <:expr< $lid:op$ $a$ $b$ >> ->
    (match expr_is_constant a, expr_is_constant b with
     | Some a, Some b ->	       (* Integer binary operations. *)
         let ops = ["+", (+); "-", (-); "*", ( * ); "/", (/);
		    (* NB: explicit fun .. -> is necessary here to work
		     * around a camlp4 bug in OCaml 3.10.0.
		     *)
                    "land", (fun a b -> a land b);
		    "lor", (fun a b -> a lor b);
		    "lxor", (fun a b -> a lxor b);
                    "lsl", (fun a b -> a lsl b);
		    "lsr", (fun a b -> a lsr b);
		    "asr", (fun a b -> a asr b);
		    "mod", (fun a b -> a mod b)] in
         (try Some ((List.assoc op ops) a b) with Not_found -> None)
     | _ -> None)
  | _ -> None

(* Generate a fresh, unique symbol each time called. *)
let gensym =
  let i = ref 1000 in
  fun name ->
    incr i; let i = !i in
    sprintf "__pabitstring_%s_%d" name i

(* Used to keep track of which qualifiers we've seen in parse_field. *)
type whatset_t = {
  endian_set : bool; signed_set : bool; type_set : bool;
  offset_set : bool; check_set : bool; bind_set : bool;
  save_offset_to_set : bool;
}
let noneset = {
  endian_set = false; signed_set = false; type_set = false;
  offset_set = false; check_set = false; bind_set = false;
  save_offset_to_set = false
}

(* Deal with the qualifiers which appear for a field of both types. *)
let parse_field _loc field qs =
  let fail = locfail _loc in

  let whatset, field =
    match qs with
    | None -> noneset, field
    | Some qs ->
        let check already_set msg = if already_set then fail msg in
        let apply_qualifier (whatset, field) =
	  function
          | "endian", Some expr ->
              check whatset.endian_set "an endian flag has been set already";
              let field = P.set_endian_expr field expr in
	      { whatset with endian_set = true }, field
          | "endian", None ->
	      fail "qualifier 'endian' should be followed by an expression"
          | "offset", Some expr ->
              check whatset.offset_set "an offset has been set already";
              let field = P.set_offset field expr in
	      { whatset with offset_set = true }, field
          | "offset", None ->
	      fail "qualifier 'offset' should be followed by an expression"
	  | "check", Some expr ->
	      check whatset.check_set "a check-qualifier has been set already";
	      let field = P.set_check field expr in
	      { whatset with check_set = true }, field
	  | "check", None ->
	      fail "qualifier 'check' should be followed by an expression"
	  | "bind", Some expr ->
	      check whatset.bind_set "a bind expression has been set already";
	      let field = P.set_bind field expr in
	      { whatset with bind_set = true }, field
	  | "bind", None ->
	      fail "qualifier 'bind' should be followed by an expression"
	  | "save_offset_to", Some expr (* XXX should be a pattern *) ->
	      check whatset.save_offset_to_set
		"a save_offset_to-qualifier has been set already";
	      let id =
		match expr with
		| <:expr< $lid:id$ >> -> id
		| _ ->
		    failwith "pa_bitstring: internal error: save_offset_to only supports simple identifiers at the moment.  In future we should support full patterns." in
	      let field = P.set_save_offset_to_lident field id in
	      { whatset with save_offset_to_set = true }, field
	  | "save_offset_to", None ->
	      fail "qualifier 'save_offset_to' should be followed by a binding expression"
          | s, Some _ ->
	      fail (s ^ ": unknown qualifier, or qualifier should not be followed by an expression")
          | qual, None ->
              let endian_quals = ["bigendian", BigEndian;
                                  "littleendian", LittleEndian;
                                  "nativeendian", NativeEndian] in
              let sign_quals = ["signed", true; "unsigned", false] in
              let type_quals = ["int", P.set_type_int;
				"string", P.set_type_string;
				"bitstring", P.set_type_bitstring] in
              if List.mem_assoc qual endian_quals then (
		check whatset.endian_set "an endian flag has been set already";
		let field = P.set_endian field (List.assoc qual endian_quals) in
		{ whatset with endian_set = true }, field
              ) else if List.mem_assoc qual sign_quals then (
		check whatset.signed_set "a signed flag has been set already";
		let field = P.set_signed field (List.assoc qual sign_quals) in
		{ whatset with signed_set = true }, field
              ) else if List.mem_assoc qual type_quals then (
		check whatset.type_set "a type flag has been set already";
		let field = (List.assoc qual type_quals) field in
		{ whatset with type_set = true }, field
              ) else
		fail (qual ^ ": unknown qualifier, or qualifier should be followed by an expression") in
        List.fold_left apply_qualifier (noneset, field) qs in

  (* If type is set to string or bitstring then endianness and
   * signedness qualifiers are meaningless and must not be set.
   *)
  let () =
    let t = P.get_type field in
    if (t = P.Bitstring || t = P.String) &&
      (whatset.endian_set || whatset.signed_set) then
	fail "string types and endian or signed qualifiers cannot be mixed" in

  (* Default endianness, signedness, type if not set already. *)
  let field =
    if whatset.endian_set then field else P.set_endian field BigEndian in
  let field =
    if whatset.signed_set then field else P.set_signed field false in
  let field =
    if whatset.type_set then field else P.set_type_int field in

  field

type functype = ExtractFunc | ConstructFunc

(* Choose the right constructor function. *)
let build_bitstring_call _loc functype length endian signed =
  match functype, length, endian, signed with
    (* XXX The meaning of signed/unsigned breaks down at
     * 31, 32, 63 and 64 bits.
     *)
  | (ExtractFunc, Some 1, _, _) -> <:expr< Bitstring.extract_bit >>
  | (ConstructFunc, Some 1, _, _) -> <:expr< Bitstring.construct_bit >>
  | (functype, Some (2|3|4|5|6|7|8), _, signed) ->
      let funcname = match functype with
	| ExtractFunc -> "extract"
	| ConstructFunc -> "construct" in
      let sign = if signed then "signed" else "unsigned" in
      let call = sprintf "%s_char_%s" funcname sign in
      <:expr< Bitstring.$lid:call$ >>
  | (functype, len, endian, signed) ->
      let funcname = match functype with
	| ExtractFunc -> "extract"
	| ConstructFunc -> "construct" in
      let t = match len with
	| Some i when i <= 31 -> "int"
	| Some 32 -> "int32"
	| _ -> "int64" in
      let sign = if signed then "signed" else "unsigned" in
      match endian with
      | P.ConstantEndian constant ->
          let endianness = match constant with
          | BigEndian -> "be"
          | LittleEndian -> "le"
          | NativeEndian -> "ne" in
          let call = sprintf "%s_%s_%s_%s" funcname t endianness sign in
          <:expr< Bitstring.$lid:call$ >>
      | P.EndianExpr expr ->
          let call = sprintf "%s_%s_%s_%s" funcname t "ee" sign in
          <:expr< Bitstring.$lid:call$ $expr$ >>

(* Generate the code for a constructor, ie. 'BITSTRING ...'. *)
let output_constructor _loc fields =
  (* This function makes code to raise a Bitstring.Construct_failure exception
   * containing a message and the current _loc context.
   * (Thanks to Bluestorm for suggesting this).
   *)
  let construct_failure _loc msg =
    <:expr<
      Bitstring.Construct_failure
        ($`str:msg$,
	 $`str:Loc.file_name _loc$,
	 $`int:Loc.start_line _loc$,
	 $`int:Loc.start_off _loc - Loc.start_bol _loc$)
    >>
  in
  let raise_construct_failure _loc msg =
    <:expr< raise $construct_failure _loc msg$ >>
  in

  (* Bitstrings are created like the 'Buffer' module (in fact, using
   * the Buffer module), by appending snippets to a growing buffer.
   * This is reasonably efficient and avoids a lot of garbage.
   *)
  let buffer = gensym "buffer" in

  (* General exception which is raised inside the constructor functions
   * when an int expression is out of range at runtime.
   *)
  let exn = gensym "exn" in
  let exn_used = ref false in

  (* Convert each field to a simple bitstring-generating expression. *)
  let fields = List.map (
    fun field ->
      let fexpr = P.get_expr field in
      let flen = P.get_length field in
      let endian = P.get_endian field in
      let signed = P.get_signed field in
      let t = P.get_type field in
      let _loc = P.get_location field in

      let fail = locfail _loc in

      (* offset(), check(), bind(), save_offset_to() not supported in
       * constructors.
       *
       * Implementation of forward-only offsets is fairly
       * straightforward: we would need to just calculate the length of
       * padding here and add it to what has been constructed.  For
       * general offsets, including going backwards, that would require
       * a rethink in how we construct bitstrings.
       *)
      if P.get_offset field <> None then
	fail "offset expressions are not supported in BITSTRING constructors";
      if P.get_check field <> None then
	fail "check expressions are not supported in BITSTRING constructors";
      if P.get_bind field <> None then
	fail "bind expressions are not supported in BITSTRING constructors";
      if P.get_save_offset_to field <> None then
	fail "save_offset_to is not supported in BITSTRING constructors";

      (* Is flen an integer constant?  If so, what is it?  This
       * is very simple-minded and only detects simple constants.
       *)
      let flen_is_const = expr_is_constant flen in

      let int_construct_const (i, endian, signed) =
        build_bitstring_call _loc ConstructFunc (Some i) endian signed in
      let int_construct (endian, signed) =
	build_bitstring_call _loc ConstructFunc None endian signed in

      let expr =
	match t, flen_is_const with
	(* Common case: int field, constant flen.
	 *
	 * Range checks are done inside the construction function
	 * because that's a lot simpler w.r.t. types.  It might
	 * be better to move them here. XXX
	 *)
	| P.Int, Some i when i > 0 && i <= 64 ->
	    let construct_fn = int_construct_const (i,endian,signed) in
	    exn_used := true;

	    <:expr<
	      $construct_fn$ $lid:buffer$ $fexpr$ $`int:i$ $lid:exn$
	    >>

	| P.Int, Some _ ->
	    fail "length of int field must be [1..64]"

	(* Int field, non-constant length.  We need to perform a runtime
	 * test to ensure the length is [1..64].
	 *
	 * Range checks are done inside the construction function
	 * because that's a lot simpler w.r.t. types.  It might
	 * be better to move them here. XXX
	 *)
	| P.Int, None ->
	    let construct_fn = int_construct (endian,signed) in
	    exn_used := true;

	    <:expr<
	      if $flen$ >= 1 && $flen$ <= 64 then
		$construct_fn$ $lid:buffer$ $fexpr$ $flen$ $lid:exn$
	      else
		$raise_construct_failure _loc "length of int field must be [1..64]"$
	    >>

        (* String, constant length > 0, must be a multiple of 8. *)
	| P.String, Some i when i > 0 && i land 7 = 0 ->
	    let bs = gensym "bs" in
	    let j = i lsr 3 in
	    <:expr<
	      let $lid:bs$ = $fexpr$ in
	      if String.length $lid:bs$ = $`int:j$ then
		Bitstring.construct_string $lid:buffer$ $lid:bs$
	      else
		$raise_construct_failure _loc "length of string does not match declaration"$
	    >>

	(* String, constant length -1, means variable length string
	 * with no checks.
	 *)
	| P.String, Some (-1) ->
	    <:expr< Bitstring.construct_string $lid:buffer$ $fexpr$ >>

	(* String, constant length = 0 is probably an error, and so is
	 * any other value.
	 *)
	| P.String, Some _ ->
	    fail "length of string must be > 0 and a multiple of 8, or the special value -1"

	(* String, non-constant length.
	 * We check at runtime that the length is > 0, a multiple of 8,
	 * and matches the declared length.
	 *)
	| P.String, None ->
	    let bslen = gensym "bslen" in
	    let bs = gensym "bs" in
	    <:expr<
	      let $lid:bslen$ = $flen$ in
	      if $lid:bslen$ > 0 then (
		if $lid:bslen$ land 7 = 0 then (
		  let $lid:bs$ = $fexpr$ in
		  if String.length $lid:bs$ = ($lid:bslen$ lsr 3) then
		    Bitstring.construct_string $lid:buffer$ $lid:bs$
		  else
		    $raise_construct_failure _loc "length of string does not match declaration"$
		) else
		  $raise_construct_failure _loc "length of string must be a multiple of 8"$
	      ) else
		$raise_construct_failure _loc "length of string must be > 0"$
	    >>

        (* Bitstring, constant length >= 0. *)
	| P.Bitstring, Some i when i >= 0 ->
	    let bs = gensym "bs" in
	    <:expr<
	      let $lid:bs$ = $fexpr$ in
	      if Bitstring.bitstring_length $lid:bs$ = $`int:i$ then
		Bitstring.construct_bitstring $lid:buffer$ $lid:bs$
	      else
		$raise_construct_failure _loc "length of bitstring does not match declaration"$
	    >>

	(* Bitstring, constant length -1, means variable length bitstring
	 * with no checks.
	 *)
	| P.Bitstring, Some (-1) ->
	    <:expr< Bitstring.construct_bitstring $lid:buffer$ $fexpr$ >>

	(* Bitstring, constant length < -1 is an error. *)
	| P.Bitstring, Some _ ->
	    fail "length of bitstring must be >= 0 or the special value -1"

	(* Bitstring, non-constant length.
	 * We check at runtime that the length is >= 0 and matches
	 * the declared length.
	 *)
	| P.Bitstring, None ->
	    let bslen = gensym "bslen" in
	    let bs = gensym "bs" in
	    <:expr<
	      let $lid:bslen$ = $flen$ in
	      if $lid:bslen$ >= 0 then (
		let $lid:bs$ = $fexpr$ in
		if Bitstring.bitstring_length $lid:bs$ = $lid:bslen$ then
		  Bitstring.construct_bitstring $lid:buffer$ $lid:bs$
		else
		  $raise_construct_failure _loc "length of bitstring does not match declaration"$
	      ) else
		$raise_construct_failure _loc "length of bitstring must be > 0"$
	    >> in
      expr
  ) fields in

  (* Create the final bitstring.  Start by creating an empty buffer
   * and then evaluate each expression above in turn which will
   * append some more to the bitstring buffer.  Finally extract
   * the bitstring.
   *
   * XXX We almost have enough information to be able to guess
   * a good initial size for the buffer.
   *)
  let fields =
    match fields with
    | [] -> <:expr< [] >>
    | h::t -> List.fold_left (fun h t -> <:expr< $h$; $t$ >>) h t in

  let expr =
    <:expr<
      let $lid:buffer$ = Bitstring.Buffer.create () in
      $fields$;
      Bitstring.Buffer.contents $lid:buffer$
    >> in

  if !exn_used then
    <:expr<
      let $lid:exn$ = $construct_failure _loc "value out of range"$ in
      $expr$
    >>
  else
    expr

(* Generate the code for a bitmatch statement.  '_loc' is the
 * location, 'bs' is the bitstring parameter, 'cases' are
 * the list of cases to test against.
 *)
let output_bitmatch _loc bs cases =
  (* These symbols are used through the generated code to record our
   * current position within the bitstring:
   *
   *   data - original bitstring data (string, never changes)
   *   off  - current offset within data (int, increments as we move through
   *            the bitstring)
   *   len  - current remaining length within data (int, decrements as
   *            we move through the bitstring)
   *
   * Also:
   *
   *   original_off - saved offset at the start of the match (never changes)
   *   original_len - saved length at the start of the match (never changes)
   *   off_aligned  - true if the original offset is byte-aligned (allows
   *            us to make some common optimizations)
   *)
  let data = gensym "data"
  and off = gensym "off"
  and len = gensym "len"
  and original_off = gensym "original_off"
  and original_len = gensym "original_len"
  and off_aligned = gensym "off_aligned"

  (* This is where the result will be stored (a reference). *)
  and result = gensym "result" in

  (* This generates the field extraction code for each
   * field in a single case.  There must be enough remaining data
   * in the bitstring to satisfy the field.
   *
   * As we go through the fields, symbols 'data', 'off' and 'len'
   * track our position and remaining length in the bitstring.
   *
   * The whole thing is a lot of nested 'if'/'match' statements.
   * Code is generated from the inner-most (last) field outwards.
   *)
  let rec output_field_extraction inner = function
    | [] -> inner
    | field :: fields ->
	let fpatt = P.get_patt field in
	let flen = P.get_length field in
	let endian = P.get_endian field in
	let signed = P.get_signed field in
	let t = P.get_type field in
	let _loc = P.get_location field in

	let fail = locfail _loc in

	(* Is flen (field len) an integer constant?  If so, what is it?
	 * This will be [Some i] if it's a constant or [None] if it's
	 * non-constant or we couldn't determine.
	 *)
	let flen_is_const = expr_is_constant flen in

	(* Surround the inner expression by check and bind clauses, so:
	 *   if $check$ then
	 *     let $bind...$ in
	 *       $inner$
	 * where the check and bind are switched on only if they are
	 * present in the field.  (In the common case when neither
	 * clause is present, expr = inner).  Note the order of the
	 * check & bind is visible to the user and defined in the
	 * documentation, so it must not change.
	 *)
	let expr = inner in
	let expr =
	  match P.get_bind field with
	  | None -> expr
	  | Some bind_expr ->
	      <:expr< let $fpatt$ = $bind_expr$ in $expr$ >> in
	let expr =
	  match P.get_check field with
	  | None -> expr
	  | Some check_expr ->
	      <:expr< if $check_expr$ then $expr$ >> in

	(* Compute the offset of this field within the match, if it
	 * can be known at compile time.
	 *
	 * Actually, we'll compute two things: the 'natural_field_offset'
	 * is the offset assuming this field had no offset() qualifier
	 * (in other words, its position, immediately following the
	 * preceding field).  'field_offset' is the real field offset
	 * taking into account any offset() qualifier.
	 *
	 * This will be [Some i] if our current offset is known
	 * at compile time, or [None] if we can't determine it.
	 *)
	let natural_field_offset, field_offset =
	  let has_constant_offset field =
	    match P.get_offset field with
	    | None -> false
	    | Some expr ->
		match expr_is_constant expr with
		| None -> false
		| Some i -> true
	  in
	  let get_constant_offset field =
	    match P.get_offset field with
	    | None -> assert false
	    | Some expr ->
		match expr_is_constant expr with
		| None -> assert false
		| Some i -> i
	  in

	  let has_constant_len field =
	    match expr_is_constant (P.get_length field) with
	    | None -> false
	    | Some i when i > 0 -> true
	    | Some _ -> false
	  in
	  let get_constant_len field =
	    match expr_is_constant (P.get_length field) with
	    | None -> assert false
	    | Some i when i > 0 -> i
	    | Some _ -> assert false
	  in

	  (* NB: We are looping over the PRECEDING fields in reverse order. *)
	  let rec loop = function
	    (* first field has constant offset 0 *)
	    | [] -> Some 0
	    (* preceding field with constant offset & length *)
	    | f :: _
		when has_constant_offset f && has_constant_len f ->
		Some (get_constant_offset f + get_constant_len f)
	    (* preceding field with no offset & constant length *)
	    | f :: fs
		when P.get_offset f = None && has_constant_len f ->
		(match loop fs with
		 | None -> None
		 | Some offset -> Some (offset + get_constant_len f))
	    (* else, can't work out the offset *)
	    | _ -> None
	  in

	  let natural_field_offset = loop fields in

	  let field_offset =
	    match P.get_offset field with
	    | None -> natural_field_offset
	    | Some expr -> (* has an offset() clause *)
		match expr_is_constant expr with
		| None -> None
		| i -> i in

	  natural_field_offset, field_offset in

	(* Also compute if the field_offset is known to be byte-aligned at
	 * compile time, which is usually both the common and best possible
	 * case for generating optimized code.
	 *
	 * This is None if not aligned / don't know.
	 * Or Some byte_offset if we can work it out.
	 *)
	let field_offset_aligned =
	  match field_offset with
	  | None -> None		(* unknown, assume no *)
	  | Some off when off land 7 = 0 -> Some (off lsr 3)
	  | Some _ -> None in		(* definitely no *)

	(* Now build the code which matches a single field. *)
	let int_extract_const i endian signed =
          build_bitstring_call _loc ExtractFunc (Some i) endian signed in
	let int_extract endian signed =
	  build_bitstring_call _loc ExtractFunc None endian signed in

	let expr =
	  match t, flen_is_const, field_offset_aligned, endian, signed with
	    (* Very common cases: int field, constant 8/16/32/64 bit
	     * length, aligned to the match at a known offset.  We
	     * still have to check if the bitstring is aligned (can only
	     * be known at runtime) but we may be able to directly access
	     * the bytes in the string.
	     *)
	  | P.Int, Some 8, Some field_byte_offset, _, _ ->
	      let extract_fn = int_extract_const 8 endian signed in

              (* The fast-path code when everything is aligned. *)
              let fastpath =
		<:expr<
                  let o =
		    ($lid:original_off$ lsr 3) + $`int:field_byte_offset$ in
                  Char.code (String.unsafe_get $lid:data$ o)              
                >> in

              <:expr<
		if $lid:len$ >= 8 then (
                  let v =
                    if $lid:off_aligned$ then
                      $fastpath$
                    else
                      $extract_fn$ $lid:data$ $lid:off$ $lid:len$ 8 in
                  let $lid:off$ = $lid:off$ + 8
                  and $lid:len$ = $lid:len$ - 8 in
                  match v with $fpatt$ when true -> $expr$ | _ -> ()
		)                                                               
	      >>

	  | P.Int, Some ((16|32|64) as i),
	    Some field_byte_offset, (P.ConstantEndian _ as endian), signed ->
	      let extract_fn = int_extract_const i endian signed in

	      (* The fast-path code when everything is aligned. *)
	      let fastpath =
		let fastpath_call =
		  let endian = match endian with
		    | P.ConstantEndian BigEndian -> "be"
		    | P.ConstantEndian LittleEndian -> "le"
		    | P.ConstantEndian NativeEndian -> "ne"
		    | P.EndianExpr _ -> assert false in
		  let signed = if signed then "signed" else "unsigned" in
		  let name =
		    sprintf "extract_fastpath_int%d_%s_%s" i endian signed in
		  match i with
		  | 16 ->
		      <:expr< Bitstring.$lid:name$ $lid:data$ o >>
		  | 32 ->
		      <:expr<
			(* must allocate a new zero each time *)
			let zero = Int32.of_int 0 in
			Bitstring.$lid:name$ $lid:data$ o zero
		      >>
		  | 64 ->
		      <:expr<
			(* must allocate a new zero each time *)
			let zero = Int64.of_int 0 in
			Bitstring.$lid:name$ $lid:data$ o zero
		      >>
		  | _ -> assert false in
		<:expr<
		  (* Starting offset within the string. *)
		  let o =
		    ($lid:original_off$ lsr 3) + $`int:field_byte_offset$ in
		  $fastpath_call$
	        >> in

	      let slowpath =
		<:expr<
		  $extract_fn$ $lid:data$ $lid:off$ $lid:len$ $`int:i$
		>> in

	      <:expr<
		if $lid:len$ >= $`int:i$ then (
		  let v =
		    if $lid:off_aligned$ then $fastpath$ else $slowpath$ in
		  let $lid:off$ = $lid:off$ + $`int:i$
		  and $lid:len$ = $lid:len$ - $`int:i$ in
		  match v with $fpatt$ when true -> $expr$ | _ -> ()
		)
	      >>

	  (* Common case: int field, constant flen *)
	  | P.Int, Some i, _, _, _ when i > 0 && i <= 64 ->
	      let extract_fn = int_extract_const i endian signed in
	      let v = gensym "val" in
	      <:expr<
		if $lid:len$ >= $`int:i$ then (
		  let $lid:v$ =
		    $extract_fn$ $lid:data$ $lid:off$ $lid:len$ $`int:i$ in
		  let $lid:off$ = $lid:off$ + $`int:i$
		  and $lid:len$ = $lid:len$ - $`int:i$ in
		  match $lid:v$ with $fpatt$ when true -> $expr$ | _ -> ()
		)
	      >>

	  | P.Int, Some _, _, _, _ ->
	      fail "length of int field must be [1..64]"

	  (* Int field, non-const flen.  We have to test the range of
	   * the field at runtime.  If outside the range it's a no-match
	   * (not an error).
	   *)
	  | P.Int, None, _, _, _ ->
	      let extract_fn = int_extract endian signed in
	      let v = gensym "val" in
	      <:expr<
		if $flen$ >= 1 && $flen$ <= 64 && $flen$ <= $lid:len$ then (
		  let $lid:v$ =
		    $extract_fn$ $lid:data$ $lid:off$ $lid:len$ $flen$ in
		  let $lid:off$ = $lid:off$ + $flen$
		  and $lid:len$ = $lid:len$ - $flen$ in
		  match $lid:v$ with $fpatt$ when true -> $expr$ | _ -> ()
		)
	      >>

          (* String, constant flen > 0.
	   * The field is at a known byte-aligned offset so we may
	   * be able to optimize the substring extraction.
	   *)
	  | P.String, Some i, Some field_byte_offset, _, _
	      when i > 0 && i land 7 = 0 ->
	      let fastpath =
		<:expr<
		  (* Starting offset within the string. *)
		  let o =
		    ($lid:original_off$ lsr 3) + $`int:field_byte_offset$ in
		  String.sub $lid:data$ o $`int:(i lsr 3)$
		>> in

	      let slowpath =
		<:expr<
		  Bitstring.string_of_bitstring
		    ($lid:data$, $lid:off$, $`int:i$)
		>> in

	      let cond =
		<:expr<
		  if $lid:off_aligned$ then $fastpath$ else $slowpath$
		>> in

	      <:expr<
		if $lid:len$ >= $`int:i$ then (
		  let str = $cond$ in
		  let $lid:off$ = $lid:off$ + $`int:i$
		  and $lid:len$ = $lid:len$ - $`int:i$ in
		  match str with
		  | $fpatt$ when true -> $expr$
		  | _ -> ()
		)
	      >>

          (* String, constant flen > 0. *)
	  | P.String, Some i, None, _, _ when i > 0 && i land 7 = 0 ->
	      <:expr<
		if $lid:len$ >= $`int:i$ then (
		  let str =
		    Bitstring.string_of_bitstring
		      ($lid:data$, $lid:off$, $`int:i$) in
		  let $lid:off$ = $lid:off$ + $`int:i$
		  and $lid:len$ = $lid:len$ - $`int:i$ in
		  match str with
		  | $fpatt$ when true -> $expr$
		  | _ -> ()
		)
	      >>

          (* String, constant flen = -1, means consume all the
	   * rest of the input.
	   * XXX It should be possible to optimize this for known byte
	   * offset, but the optimization is tricky because the end/length
	   * of the string may not be byte-aligned.
	   *)
	  | P.String, Some i, _, _, _ when i = -1 ->
	      let str = gensym "str" in

	      <:expr<
		let $lid:str$ =
		  Bitstring.string_of_bitstring
		    ($lid:data$, $lid:off$, $lid:len$) in
		let $lid:off$ = $lid:off$ + $lid:len$ in
		let $lid:len$ = 0 in
		match $lid:str$ with
		| $fpatt$ when true -> $expr$
		| _ -> ()
	      >>

	  | P.String, Some _, _, _, _ ->
	      fail "length of string must be > 0 and a multiple of 8, or the special value -1"

	  (* String field, non-const flen.  We check the flen is > 0
	   * and a multiple of 8 (-1 is not allowed here), at runtime.
	   *)
	  | P.String, None, _, _, _ ->
	      let bs = gensym "bs" in
	      <:expr<
		if $flen$ >= 0 && $flen$ <= $lid:len$
		  && $flen$ land 7 = 0 then (
		    let $lid:bs$ = ($lid:data$, $lid:off$, $flen$) in
		    let $lid:off$ = $lid:off$ + $flen$
		    and $lid:len$ = $lid:len$ - $flen$ in
		    match Bitstring.string_of_bitstring $lid:bs$ with
		    | $fpatt$ when true -> $expr$
		    | _ -> ()
		  )
	      >>

          (* Bitstring, constant flen >= 0.
	   * At the moment all we can do is assign the bitstring to an
	   * identifier.
	   *)
	  | P.Bitstring, Some i, _, _, _ when i >= 0 ->
	      let ident =
		match fpatt with
		| <:patt< $lid:ident$ >> -> ident
		| <:patt< _ >> -> "_"
		| _ ->
		    fail "cannot compare a bitstring to a constant" in
	      <:expr<
		if $lid:len$ >= $`int:i$ then (
		  let $lid:ident$ = ($lid:data$, $lid:off$, $`int:i$) in
		  let $lid:off$ = $lid:off$ + $`int:i$
		  and $lid:len$ = $lid:len$ - $`int:i$ in
		  $expr$
		)
	      >>

          (* Bitstring, constant flen = -1, means consume all the
	   * rest of the input.
	   *)
	  | P.Bitstring, Some i, _, _, _ when i = -1 ->
	      let ident =
		match fpatt with
		| <:patt< $lid:ident$ >> -> ident
		| <:patt< _ >> -> "_"
		| _ ->
		    fail "cannot compare a bitstring to a constant" in
	      <:expr<
		let $lid:ident$ = ($lid:data$, $lid:off$, $lid:len$) in
		let $lid:off$ = $lid:off$ + $lid:len$ in
		let $lid:len$ = 0 in
		  $expr$
	      >>

	  | P.Bitstring, Some _, _, _, _ ->
	      fail "length of bitstring must be >= 0 or the special value -1"

	  (* Bitstring field, non-const flen.  We check the flen is >= 0
	   * (-1 is not allowed here) at runtime.
	   *)
	  | P.Bitstring, None, _, _, _ ->
	      let ident =
		match fpatt with
		| <:patt< $lid:ident$ >> -> ident
		| <:patt< _ >> -> "_"
		| _ ->
		    fail "cannot compare a bitstring to a constant" in
	      <:expr<
		if $flen$ >= 0 && $flen$ <= $lid:len$ then (
		  let $lid:ident$ = ($lid:data$, $lid:off$, $flen$) in
		  let $lid:off$ = $lid:off$ + $flen$
		  and $lid:len$ = $lid:len$ - $flen$ in
		  $expr$
		)
	      >>
	in

	(* Computed offset: only offsets forward are supported.
	 *
	 * We try hard to optimize this based on what we know.  Are
	 * we at a predictable offset now?  (Look at the outer 'fields'
	 * list and see if they all have constant field length starting
	 * at some constant offset).  Is this offset constant?
	 *
	 * Based on this we can do a lot of the computation at
	 * compile time, or defer it to runtime only if necessary.
	 *
	 * In all cases, the off and len fields get updated.
	 *)
	let expr =
	  match P.get_offset field with
	  | None -> expr (* common case: there was no offset expression *)
	  | Some offset_expr ->
	      (* This will be [Some i] if offset is a constant expression
	       * or [None] if it's a non-constant.
	       *)
	      let requested_offset = expr_is_constant offset_expr in

              (* Look at the field offset (if known) and requested offset
	       * cases and determine what code to generate.
	       *)
	      match natural_field_offset, requested_offset with
		(* This is the good case: both the field offset and
		 * the requested offset are constant, so we can remove
		 * almost all the runtime checks.
		 *)
	      | Some natural_field_offset, Some requested_offset ->
		  let move = requested_offset - natural_field_offset in
		  if move < 0 then
		    fail (sprintf "requested offset is less than the field offset (%d < %d)" requested_offset natural_field_offset);
		  (* Add some code to move the offset and length by a
		   * constant amount, and a runtime test that len >= 0
		   * (XXX possibly the runtime test is unnecessary?)
		   *)
		  <:expr<
		    let $lid:off$ = $lid:off$ + $`int:move$ in
		    let $lid:len$ = $lid:len$ - $`int:move$ in
		    if $lid:len$ >= 0 then $expr$
		  >>
	      (* In any other case, we need to use runtime checks.
	       *
	       * XXX It's not clear if a backwards move detected at runtime
	       * is merely a match failure, or a runtime error.  At the
	       * moment it's just a match failure since bitmatch generally
	       * doesn't raise runtime errors.
	       *)
	      | _ ->
		  let move = gensym "move" in
		  <:expr<
		    let $lid:move$ =
		      $offset_expr$ - ($lid:off$ - $lid:original_off$) in
		    if $lid:move$ >= 0 then (
		      let $lid:off$ = $lid:off$ + $lid:move$ in
		      let $lid:len$ = $lid:len$ - $lid:move$ in
		      if $lid:len$ >= 0 then $expr$
		    )
		  >> in (* end of computed offset code *)

	(* save_offset_to(patt) saves the current offset into a variable. *)
	let expr =
	  match P.get_save_offset_to field with
	  | None -> expr (* no save_offset_to *)
	  | Some patt ->
	      <:expr<
		let $patt$ = $lid:off$ - $lid:original_off$ in
		$expr$
	      >> in

	(* Emit extra debugging code. *)
	let expr =
	  if not debug then expr else (
	    let field = P.string_of_pattern_field field in

	    <:expr<
	      if !Bitstring.debug then (
		Printf.eprintf "PA_BITSTRING: TEST:\n";
		Printf.eprintf "  %s\n" $str:field$;
		Printf.eprintf "  off %d len %d\n%!" $lid:off$ $lid:len$;
		(*Bitstring.hexdump_bitstring stderr
		  ($lid:data$,$lid:off$,$lid:len$);*)
	      );
	      $expr$
	    >>
	  ) in

	output_field_extraction expr fields
  in

  (* Convert each case in the match. *)
  let cases = List.map (
    fun (fields, bind, whenclause, code) ->
      let inner = <:expr< $lid:result$ := Some ($code$); raise Exit >> in
      let inner =
	match whenclause with
	| Some whenclause ->
	    <:expr< if $whenclause$ then $inner$ >>
	| None -> inner in
      let inner =
	match bind with
	| Some name ->
	    <:expr<
	      let $lid:name$ = ($lid:data$, $lid:off$, $lid:len$) in
	      $inner$
	      >>
	| None -> inner in
      output_field_extraction inner (List.rev fields)
  ) cases in

  (* Join them into a single expression.
   *
   * Don't do it with a normal fold_right because that leaves
   * 'raise Exit; ()' at the end which causes a compiler warning.
   * Hence a bit of complexity here.
   *
   * Note that the number of cases is always >= 1 so List.hd is safe.
   *)
  let cases = List.rev cases in
  let cases =
    List.fold_left (fun base case -> <:expr< $case$ ; $base$ >>)
      (List.hd cases) (List.tl cases) in

  (* The final code just wraps the list of cases in a
   * try/with construct so that each case is tried in
   * turn until one case matches (that case sets 'result'
   * and raises 'Exit' to leave the whole statement).
   * If result isn't set by the end then we will raise
   * Match_failure with the location of the bitmatch
   * statement in the original code.
   *)
  let loc_fname = Loc.file_name _loc in
  let loc_line = string_of_int (Loc.start_line _loc) in
  let loc_char = string_of_int (Loc.start_off _loc - Loc.start_bol _loc) in

  <:expr<
    (* Note we save the original offset/length at the start of the match
     * in 'original_off'/'original_len' symbols.  'data' never changes.
     * This code also ensures that if original_off/original_len/off_aligned
     * aren't actually used, we don't get a warning.
     *)
    let ($lid:data$, $lid:original_off$, $lid:original_len$) = $bs$ in
    let $lid:off$ = $lid:original_off$ and $lid:len$ = $lid:original_len$ in
    let $lid:off_aligned$ = $lid:off$ land 7 = 0 in
    ignore $lid:off_aligned$;
    let $lid:result$ = ref None in
    (try
      $cases$
    with Exit -> ());
    match ! $lid:result$ with
    | Some x -> x
    | None -> raise (Match_failure ($str:loc_fname$,
				    $int:loc_line$, $int:loc_char$))
  >>

(* Add a named pattern. *)
let add_named_pattern _loc name pattern =
  Hashtbl.add pattern_hash name pattern

(* Expand a named pattern from the pattern_hash. *)
let expand_named_pattern _loc name =
  try Hashtbl.find pattern_hash name
  with Not_found ->
    locfail _loc (sprintf "named pattern not found: %s" name)

(* Add named patterns from a file.  See the documentation on the
 * directory search path in bitstring_persistent.mli
 *)
let load_patterns_from_file _loc filename =
  let chan =
    if Filename.is_relative filename && Filename.is_implicit filename then (
      (* Try current directory. *)
      try open_in filename
      with _ ->
	(* Try OCaml library directory. *)
	try open_in (Filename.concat Bitstring_config.ocamllibdir filename)
	with exn -> Loc.raise _loc exn
    ) else (
      try open_in filename
      with exn -> Loc.raise _loc exn
    ) in
  let names = ref [] in
  (try
     let rec loop () =
       let name = P.named_from_channel chan in
       names := name :: !names
     in
     loop ()
   with End_of_file -> ()
  );
  close_in chan;
  let names = List.rev !names in
  List.iter (
    function
    | name, P.Pattern patt ->
	if patt = [] then
	  locfail _loc (sprintf "pattern %s: no fields" name);
	add_named_pattern _loc name patt
    | _, P.Constructor _ -> () (* just ignore these for now *)
  ) names

EXTEND Gram
  GLOBAL: expr str_item;

  (* Qualifiers are a list of identifiers ("string", "bigendian", etc.)
   * followed by an optional expression (used in certain cases).  Note
   * that we are careful not to declare any explicit reserved words.
   *)
  qualifiers: [
    [ LIST0
	[ q = LIDENT;
	  e = OPT [ "("; e = expr; ")" -> e ] -> (q, e) ]
	SEP "," ]
  ];

  (* Field used in the bitmatch operator (a pattern).  This can actually
   * return multiple fields, in the case where the 'field' is a named
   * persitent pattern.
   *)
  patt_field: [
    [ fpatt = patt; ":"; len = expr LEVEL "top";
      qs = OPT [ ":"; qs = qualifiers -> qs ] ->
	let field = P.create_pattern_field _loc in
	let field = P.set_patt field fpatt in
	let field = P.set_length field len in
	[parse_field _loc field qs]	(* Normal, single field. *)
    | ":"; name = LIDENT ->
	expand_named_pattern _loc name (* Named -> list of fields. *)
    ]
  ];

  (* Case inside bitmatch operator. *)
  patt_fields: [
    [ "{";
      fields = LIST0 patt_field SEP ";";
      "}" ->
	List.concat fields
    | "{";
      "_";
      "}" ->
	[]
    ]
  ];

  patt_case: [
    [ fields = patt_fields;
      bind = OPT [ "as"; name = LIDENT -> name ];
      whenclause = OPT [ "when"; e = expr -> e ]; "->";
      code = expr ->
	(fields, bind, whenclause, code)
    ]
  ];

  (* Field used in the BITSTRING constructor (an expression). *)
  constr_field: [
    [ fexpr = expr LEVEL "top"; ":"; len = expr LEVEL "top";
      qs = OPT [ ":"; qs = qualifiers -> qs ] ->
	let field = P.create_constructor_field _loc in
	let field = P.set_expr field fexpr in
	let field = P.set_length field len in
	parse_field _loc field qs
    ]
  ];

  constr_fields: [
    [ "{";
      fields = LIST0 constr_field SEP ";";
      "}" ->
	fields
    ]
  ];

  (* 'bitmatch' expressions. *)
  expr: LEVEL ";" [
    [ "bitmatch";
      bs = expr; "with"; OPT "|";
      cases = LIST1 patt_case SEP "|" ->
	output_bitmatch _loc bs cases
    ]

  (* Constructor. *)
  | [ "BITSTRING";
      fields = constr_fields ->
	output_constructor _loc fields
    ]
  ];

  (* Named persistent patterns.
   *
   * NB: Currently only allowed at the top level.  We can probably lift
   * this restriction later if necessary.  We only deal with patterns
   * at the moment, not constructors, but the infrastructure to do
   * constructors is in place.
   *)
  str_item: LEVEL "top" [
    [ "let"; "bitmatch";
      name = LIDENT; "="; fields = patt_fields ->
	add_named_pattern _loc name fields;
        (* The statement disappears, but we still need a str_item so ... *)
        <:str_item< >>
    | "open"; "bitmatch"; filename = STRING ->
	load_patterns_from_file _loc filename;
	<:str_item< >>
    ]
  ];

END
