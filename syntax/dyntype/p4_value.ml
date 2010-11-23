(*pp camlp4orf *)
(*
 * Copyright (c) 2009 Thomas Gazagnaire <thomas@gazagnaire.com>
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
 *)

(* Fork of http://xenbits.xen.org/xapi/xen-api-libs.hg?file/7a17b2ab5cfc/rpc-light/pa_rpc.ml *)


open Camlp4
open PreCast
open Ast
open P4_helpers

let value_of n = "value_of_" ^ n
let of_value n = n ^ "_of_value"

let of_value_aux n = n ^ "_of_value_aux"
let value_of_aux n = "value_of_" ^ n ^ "_aux"

let gen_id      n = "gen_" ^ n ^ "_id"
let init_gen_id n = "init_gen_id_" ^ n

(* Utils *)

let debug_ctyp ctyp =
	let module PP = Camlp4.Printers.OCaml.Make(Syntax) in
	let pp = new PP.printer () in
	Format.printf "unknown type %a@.\n" pp#ctyp ctyp

let list_of_ctyp_decl tds =
	let rec aux accu = function
	| Ast.TyAnd (loc, tyl, tyr)      -> aux (aux accu tyl) tyr
	| Ast.TyDcl (loc, id, _, ty, []) -> (id, ty) :: accu
	| _                               ->  failwith "list_of_ctyp_decl: unexpected type"
	in aux [] tds

let rec decompose_fields _loc fields =
	match fields with
	| <:ctyp< $t1$; $t2$ >> ->
		decompose_fields _loc t1 @ decompose_fields _loc t2
	| <:ctyp< $lid:field_name$: mutable $t$ >> | <:ctyp< $lid:field_name$: $t$ >> ->
		[ field_name, t ]
	| _ -> failwith "unexpected type while processing fields"

let decompose_variants _loc variant =
	let rec fn accu = function
	| <:ctyp< $t$ | $u$ >>        -> fn (fn accu t) u
	| <:ctyp< $uid:id$ of $t$ >>  -> ((id, `V) , list_of_ctyp t []) :: accu
	| <:ctyp< `$uid:id$ of $t$ >> -> ((id, `PV), list_of_ctyp t []) :: accu
	| <:ctyp< $uid:id$ >>         -> ((id, `V) , []) :: accu
	| <:ctyp< `$uid:id$ >>        -> ((id, `PV), []) :: accu
	| _ -> failwith "decompose_variant"
	in
	List.split (fn [] variant)

let recompose_variant _loc (n, t) patts =
	match t, patts with
	| `V , [] -> <:patt< $uid:n$ >>
	| `PV, [] -> <:patt< `$uid:n$ >>
	| `V , _  -> <:patt< $uid:n$ $patt_tuple_of_list _loc patts$ >>
	| `PV, _  -> <:patt< `$uid:n$ $patt_tuple_of_list _loc patts$ >>

let count = ref 0
let new_id _loc =
	incr count;
	let new_id = Printf.sprintf "__x%i__" !count in
	<:expr< $lid:new_id$ >>, <:patt< $lid:new_id$ >>

let new_id_list _loc l =
	List.split (List.map (fun _ -> new_id _loc) l)

exception Type_not_supported of ctyp

(* Conversion ML type -> Value.t *)
module Value_of = struct
	
	let env_type _loc names =
		let aux accu n = <:ctyp< $lid:n$ : list ( $lid:n$ * int64 ); $accu$ >> in
		<:ctyp< { $List.fold_left aux <:ctyp< >>  names$ } >>

	let empty_env _loc names =
		let aux n = <:rec_binding< Deps.$lid:n$ = [] >> in
		<:expr< { $rbSem_of_list (List.map aux names)$ } >>

	let replace_env _loc names id t =
		if List.length names = 1 then
			<:expr< { Deps.$lid:t$ = [ ($id$, __id__) :: __env__.Deps.$lid:t$ ] } >>
		else
			<:expr< { (__env__) with Deps.$lid:t$ = [ ($id$, __id__) :: __env__.Deps.$lid:t$ ] } >>


	let gen_id_default _loc n =
		<:expr< fun $lid:n$ -> do { id_seed.val := Int64.add id_seed.val 1L; id_seed.val }
		>>

	let gen_binding _loc gen_id_fn n = 
		<:binding< $lid:gen_id n$ = fun ~id_seed -> $gen_id_fn _loc n$ >>

	let id_seed_default _loc = Some <:expr< ref 0L >>,  <:ctyp< ref Int64.t >>

	let rec create names id ctyp =
		let _loc = loc_of_ctyp ctyp in
		match ctyp with
		| <:ctyp< unit >>    -> <:expr< V.Unit >>
		| <:ctyp< int >>     -> <:expr< V.Int (Int64.of_int $id$) >>
		| <:ctyp< int32 >>   -> <:expr< V.Int (Int64.of_int32 $id$) >>
		| <:ctyp< int64 >>   -> <:expr< V.Int $id$ >>
		| <:ctyp< float >>   -> <:expr< V.Float $id$ >>
		| <:ctyp< char >>    -> <:expr< V.Int (Int64.of_int (Char.code $id$)) >>
		| <:ctyp< string >>  -> <:expr< V.String $id$ >>
		| <:ctyp< bool >>    -> <:expr< V.Bool $id$ >>

		| <:ctyp< [< $t$ ] >> | <:ctyp< [> $t$ ] >> | <:ctyp< [= $t$ ] >> | <:ctyp< [ $t$ ] >> ->
			let ids, ctyps = decompose_variants _loc t in
			let pattern (n, t) ctyps =
				let ids, pids = new_id_list _loc ctyps in
				let body = <:expr< V.Sum ( $str:n$, $expr_list_of_list _loc (List.map2 (create names) ids ctyps)$ ) >> in
				<:match_case< $recompose_variant _loc (n,t) pids$ -> $body$ >> in
			let patterns = mcOr_of_list (List.map2 pattern ids ctyps) in
			<:expr< match $id$ with [ $patterns$ ] >>

		| <:ctyp< option $t$ >> ->
			let new_id, new_pid = new_id _loc in
			<:expr< match $id$ with [ Some $new_pid$ -> V.Value $create names new_id t$ | None -> V.Null ] >> 

		| <:ctyp< $tup:tp$ >> ->
			let ctyps = list_of_ctyp tp [] in
			let ids, pids = new_id_list _loc ctyps in
			let exprs = List.map2 (create names) ids ctyps in
			<:expr<
				let $patt_tuple_of_list _loc pids$ = $id$ in
				V.Tuple $expr_list_of_list _loc exprs$
			>>

		| <:ctyp< list $t$ >> ->
			let new_id, new_pid = new_id _loc in
			<:expr< V.Enum (List.map (fun $new_pid$ -> $create names new_id t$) $id$) >>

		| <:ctyp< array $t$ >> ->
			let new_id, new_pid = new_id _loc in
			<:expr< V.Enum (Array.to_list (Array.map (fun $new_pid$ -> $create names new_id t$) $id$)) >>

		| <:ctyp< { $t$ } >> ->
			let fields = decompose_fields _loc t in
            let ids, pids = new_id_list _loc fields in
			let bindings = List.map2 (fun pid (f, _) -> <:binding< $pid$ = $id$ . $lid:f$ >>) pids fields in
			let one_expr nid (n, ctyp) = <:expr< ($str:n$, $create names nid ctyp$) >> in
			let expr = <:expr< V.Dict $expr_list_of_list _loc (List.map2 one_expr ids fields)$ >> in
			<:expr< let $biAnd_of_list bindings$ in $expr$ >>

		| <:ctyp< < $t$ > >> ->
			let fields = decompose_fields _loc t in
            let ids, pids = new_id_list _loc fields in
			let bindings = List.map2 (fun pid (f, _) -> <:binding< $pid$ = $id$ # $lid:f$ >>) pids fields in
			let one_expr nid (n, ctyp) = <:expr< ($str:n$, $create names nid ctyp$) >> in
			let expr = <:expr< V.Dict $expr_list_of_list _loc (List.map2 one_expr ids fields)$ >> in
			<:expr< let $biAnd_of_list bindings$ in $expr$ >>

		| <:ctyp< $t$ -> $u$ >> -> <:expr< V.Arrow (let module M = Marshal in M.to_string $id$  [ M.Closures ]) >>

		| <:ctyp< $lid:t$ >> ->
			if not (List.mem t names) then
				<:expr< $lid:value_of t$ ~id_seed $id$ >>
			else
				<:expr<
					if List.mem_assq $id$ __env__.Deps.$lid:t$
					then V.Var ($str:t$, List.assq $id$ __env__.Deps.$lid:t$)
					else begin
						let __id__ = $lid:gen_id t$ ~id_seed $id$ in
						let __value__ = $lid:value_of_aux t$ ~id_seed $replace_env _loc names id t$ $id$ in
						if List.mem ($str:t$, __id__) (V.free_vars __value__) then
							V.Rec (($str:t$, __id__), __value__)
						else
							V.Ext (($str:t$, __id__), __value__)
					end >>

		| _ -> raise (Type_not_supported ctyp)

	let gen_one names name ctyp =
		let _loc = loc_of_ctyp ctyp in
		let id, pid = new_id _loc in
		<:binding< $lid:value_of_aux name$ =
			fun ~id_seed -> fun __env__ -> fun $pid$ ->
				let module V = Value in
				$create names id ctyp$
		>>

	let gen tds =
		let _loc = loc_of_ctyp tds in
		let ids, ctyps = List.split (list_of_ctyp_decl tds) in
		let bindings = List.map2 (gen_one ids) ids ctyps in
		biAnd_of_list bindings

	let inputs _loc ~id_seed_t ~opt ids =
		let value_of_fn x =
			if opt then
				<:patt< ($lid:value_of x$ : ?id_seed:$id_seed_t$ -> $lid:x$ -> Value.t) >>
			else
				<:patt< ($lid:value_of x$ : ~id_seed:$id_seed_t$ -> $lid:x$ -> Value.t) >> in
		let value_of_fns = List.map value_of_fn ids in
		patt_tuple_of_list _loc value_of_fns

	let outputs _loc ?id_seed ids =
		let value_of_fn x =
			let xe, xp = new_id _loc in
			let body =
				<:expr< fun $xp$ ->
					let __env__ = $empty_env _loc ids$ in
					let __id__ = $lid:gen_id x$ ~id_seed $xe$ in
					let __env__ = $replace_env _loc ids <:expr< $xe$ >> x$ in
					let __x__ = $lid:value_of_aux x$ ~id_seed __env__ $xe$ in
					if List.mem ($str:x$, __id__) (Value.free_vars __x__) then
						Value.Rec (($str:x$, __id__), __x__)
					else
						Value.Ext (($str:x$, $lid:gen_id x$ ~id_seed $xe$), __x__)
			>> in
			match id_seed with
			| None   -> <:expr< fun ~id_seed -> $body$ >>
			| Some d -> <:expr< fun ?(id_seed = $d$) -> $body$ >> in 
		let value_of_fns = List.map value_of_fn ids in
		expr_tuple_of_list _loc value_of_fns

end


(* Conversion Value.t -> ML type *)
module Of_value = struct

	let env_type _loc names =
		<:ctyp< { $List.fold_left (fun accu n -> <:ctyp< $lid:n$ : list (int64 * $lid:n$) ; $accu$ >>) <:ctyp< >> names$ } >>

	let empty_env _loc names =
		<:expr< { $rbSem_of_list (List.map (fun n -> <:rec_binding< Deps.$lid:n$ = [] >>) names)$ } >>

	let replace_env _loc names name =
		if List.length names = 1 then
			<:expr< { Deps.$lid:name$ = [ (__id__, __value0__) :: __env__.Deps.$lid:name$ ] } >>
		else
			<:expr< { (__env__) with Deps.$lid:name$ = [ (__id__, __value0__) :: __env__.Deps.$lid:name$ ] } >>

	let string_of_env _loc names =
		<:expr< Printf.sprintf "{%s}" (String.concat "," $expr_list_of_list _loc (List.map
			(fun n -> <:expr< Printf.sprintf "%s:%i" $str:n$ (List.length __env__.Deps.$lid:n$) >>)
			names)$) >>

	let str_of_id id = match id with <:expr@loc< $lid:s$ >> -> <:expr@loc< $str:s$ >> | _ -> assert false

	let runtime_error id expected =
		let _loc = Loc.ghost in
		<:match_case<  __x__ -> do {
			Printf.printf "Runtime error while parsing '%s': got '%s' while '%s' was expected\\n" $str_of_id id$ (Value.to_string __x__) $str:expected$;
			raise (Deps.Runtime_error($str:expected$, __x__)) }
		>>

	let runtime_exn_error id doing =
		let _loc = Loc.ghost in
		<:match_case< __x__ -> do {
			Printf.printf "Runtime error while parsing '%s': got exception '%s' doing '%s'\\n" $str_of_id id$ (Printexc.to_string __x__) $str:doing$;
			raise (Deps.Runtime_exn_error($str:doing$, __x__)) }
		>>

	let rec create names id ctyp =
		let _loc = loc_of_ctyp ctyp in
		match ctyp with
		| <:ctyp< unit >>   -> <:expr< match $id$ with [ V.Unit -> () | $runtime_error id "Unit"$ ] >>
		| <:ctyp< int >>    -> <:expr< match $id$ with [ V.Int x -> Int64.to_int x | $runtime_error id "Int(int)"$ ] >>
		| <:ctyp< int32 >>  -> <:expr< match $id$ with [ V.Int x -> Int64.to_int32 x | $runtime_error id "Int(int32)"$ ] >>
		| <:ctyp< int64 >>  -> <:expr< match $id$ with [ V.Int x ->  x | $runtime_error id "Int(int64)"$ ] >>
		| <:ctyp< float >>  -> <:expr< match $id$ with [ V.Float x -> x | $runtime_error id "Float"$ ] >>
		| <:ctyp< char >>   -> <:expr< match $id$ with [ V.Int x -> Char.chr (Int64.to_int x) | $runtime_error id "Int(char)"$ ] >>
		| <:ctyp< string >> -> <:expr< match $id$ with [ V.String x -> x | $runtime_error id "String(string)"$ ] >>
		| <:ctyp< bool >>   -> <:expr< match $id$ with [ V.Bool x -> x | $runtime_error id "Bool"$ ] >>

		| <:ctyp< [< $t$ ] >> | <:ctyp< [> $t$ ] >> | <:ctyp< [= $t$ ] >> | <:ctyp< [ $t$ ] >> ->
			let ids, ctyps = decompose_variants _loc t in
			let pattern (n, t) ctyps =
				let ids, pids = new_id_list _loc ctyps in
				let patt = <:patt< V.Sum ( $str:n$, $patt_list_of_list _loc pids$ ) >> in
				let exprs = List.map2 (create names) ids ctyps in
				let body = List.fold_right
					(fun a b -> <:expr< $b$ $a$ >>)
					(List.rev exprs)
					(if t = `V then <:expr< $uid:n$ >> else <:expr< `$uid:n$ >>) in
				<:match_case< $patt$ -> $body$ >> in
			let fail_match = <:match_case< $runtime_error id "Sum"$ >> in
			let patterns = mcOr_of_list (List.map2 pattern ids ctyps @ [ fail_match ]) in
			<:expr< match $id$ with [ $patterns$ ] >>

		| <:ctyp< option $t$ >> ->
			let nid, npid = new_id _loc in
			<:expr< match $id$ with [ V.Null -> None | V.Value $npid$ -> Some $create names nid t$ | $runtime_error id "Null/Value"$ ] >>

		| <:ctyp< $tup:tp$ >> ->
			let ctyps = list_of_ctyp tp [] in
			let ids, pids = new_id_list _loc ctyps in
			let exprs = List.map2 (create names) ids ctyps in
			<:expr< match $id$ with
				[ V.Tuple $patt_list_of_list _loc pids$ -> $expr_tuple_of_list _loc exprs$ | $runtime_error id "List"$ ]
			>>

		| <:ctyp< list $t$ >> ->
			let nid, npid = new_id _loc in
			let nid2, npid2 = new_id _loc in
			<:expr< match $id$ with
				[ V.Enum $npid$ -> List.map (fun $npid2$ -> $create names nid2 t$) $nid$ | $runtime_error id "List"$ ]
			>>

		| <:ctyp< array $t$ >> ->
			let nid, npid = new_id _loc in
			let nid2, npid2 = new_id _loc in
			<:expr< match $id$ with
				[ V.Enum $npid$ -> Array.of_list (List.map (fun $npid2$ -> $create names nid2 t$) $nid$) | $runtime_error id "List"$ ]
			>>

		| <:ctyp< { $t$ } >> ->
			let nid, npid = new_id _loc in
			let fields = decompose_fields _loc t in
			let ids, pids = new_id_list _loc fields in
			let exprs = List.map2 (fun id (n, ctyp) -> <:rec_binding< $lid:n$ = $create names id ctyp$ >>) ids fields in
			let bindings =
				List.map2 (fun pid (n, ctyp) ->
					<:binding< $pid$ = try List.assoc $str:n$ $nid$ with _ -> V.Null >>
					) pids fields in
			<:expr< match $id$ with
				[ V.Dict $npid$ -> let $biAnd_of_list bindings$ in { $rbSem_of_list exprs$ } | $runtime_error id "Dict"$ ]
			>>

		| <:ctyp< < $t$ > >> ->
			let nid, npid = new_id _loc in
			let fields = decompose_fields _loc t in
			let ids, pids = new_id_list _loc fields in
			let exprs = List.map2 (fun id (n, ctyp) -> <:class_str_item< method $lid:n$ = $create names id ctyp$ >>) ids fields in
			let bindings =
				List.map2 (fun pid (n, ctyp) ->
					<:binding< $pid$ = try List.assoc $str:n$ $nid$ with [ $runtime_exn_error nid ("Looking for key "^n)$ ] >>
					) pids fields in
			<:expr< match $id$ with 
				[ V.Dict $npid$ -> let $biAnd_of_list bindings$ in object $crSem_of_list exprs$ end | $runtime_error id "Dict"$ ]
			>>

		| <:ctyp< $t$ -> $u$ >> ->
			<:expr< match $id$ with
				[ V.Arrow f -> (let module M = Marshal in M.from_string f : $t$ -> $u$) | $runtime_error id "Marshal"$ ]
			>>

		| <:ctyp< $lid:t$ >> ->
			if List.mem t names then
				<:expr< $lid:of_value_aux t$ __env__ $id$ >>
			else
				<:expr< $lid:of_value t$ $id$ >>

		| _ -> raise (Type_not_supported ctyp)

	let default_value _loc = function
		| <:ctyp< { $t$ } >> ->
			let fields = decompose_fields _loc t in
			let fields = List.map (fun (n, ctyp) -> <:rec_binding< $lid:n$ = Obj.magic 0 >>) fields in
			<:expr< { $rbSem_of_list fields$ } >>

		| _ -> <:expr< failwith "Cyclic values should be defined via record fields only" >>

	let set_value _loc = function
		| <:ctyp< { $t$ } >> ->
			let fields = decompose_fields _loc t in
			let field = ref (-1) in
			let fields = List.map (fun (n, ctyp) -> incr field; <:expr< Obj.set_field (Obj.repr __value0__) $`int:!field$ (Obj.field (Obj.repr __value1__) $`int:!field$) >>) fields in
			<:expr< do { $exSem_of_list fields$ } >>

		| _ -> <:expr< failwith "Cyclic values should be defined via record fields only"  >>

	let gen_one names name ctyp =
		let _loc = loc_of_ctyp ctyp in
		let nid, npid = new_id _loc in
		let nid2, npid2 = new_id _loc in
		<:binding< $lid:of_value_aux name$ = fun __env__ -> fun $npid$ ->
			let module V = Value in
			match $nid$ with [
			  V.Var (n, __id__) -> List.assoc __id__ __env__.Deps.$lid:name$
			| V.Rec ((n, __id__), $npid2$ ) ->
				if List.mem_assoc __id__ __env__.Deps.$lid:name$ then
					List.assoc __id__ __env__.Deps.$lid:name$
				else
					let __value0__ = $default_value _loc ctyp$ in
					let __env__  = $replace_env _loc names name$ in
					let __value1__ = $create names nid2 ctyp$ in 
					let () = $set_value _loc ctyp$ in
					__value0__
			| V.Ext (n, $npid2$) -> $create names nid2 ctyp$
			| $runtime_error nid "Var/Rec/Ext"$ ]
		>>

	let gen tds =
		let _loc = loc_of_ctyp tds in
		let ids, ctyps = List.split (list_of_ctyp_decl tds) in
		let bindings = List.map2 (gen_one ids) ids ctyps in
		biAnd_of_list bindings

	let inputs _loc ids =
		let of_value_fns = List.map (fun x -> <:patt< ($lid:of_value x$ : Value.t -> $lid:x$) >>) ids in
		patt_tuple_of_list _loc of_value_fns

	let outputs _loc ids =
		let of_value_fns = List.map (fun x -> <:expr< $lid:of_value_aux x$ $empty_env _loc ids$ >>) ids in
		expr_tuple_of_list _loc of_value_fns
end

let gen ?(gen_id=Value_of.gen_id_default) ?(id_seed=Value_of.id_seed_default) tds =
	let _loc = loc_of_ctyp tds in
	let ids, _ = List.split (list_of_ctyp_decl tds) in
	let id_seed, id_seed_t = id_seed _loc in
	<:str_item<
		value $Value_of.inputs _loc ~id_seed_t ~opt:(id_seed<>None) ids$ =
			let module Deps = struct
				type env = $Value_of.env_type _loc ids$;
			end in
			let $biAnd_of_list (List.map (Value_of.gen_binding _loc gen_id) ids)$ in
			let rec $Value_of.gen tds$ in
			$Value_of.outputs _loc ?id_seed ids$;
		value $Of_value.inputs _loc ids$ =
			let module Deps = struct
				type env = $Of_value.env_type _loc ids$;
				exception Runtime_error of (string * Value.t);
				exception Runtime_exn_error of (string * exn);
			end in
			let rec $Of_value.gen tds$ in
			$Of_value.outputs _loc ids$;
	>>


