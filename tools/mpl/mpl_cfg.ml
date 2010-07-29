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
 * $Id: mpl_cfg.ml,v 1.20 2006/02/17 17:28:40 avsm Exp $
 *)

open Printf
open Mpl_syntaxtree
open Mpl_utils

module V = Mpl_typechk.Var
module E = Mpl_typechk.Expr
module B = Mpl_bits

type vt = {
	vt_ty: V.b;                (* type of the mapping *)
	vt_b: (expr * string) list;  (* actual mappings, expr -> variant id *)
	vt_def: string option;     (* default variant, if any *)
} and
vts = (string,vt) Hashtbl.t (* variant name -> vt Hashtable *)

type env = {
    vars: (string * V.x) list;
	 statevars: (string * V.b) list;
    offsets: (string, unit) Hashtbl.t;
    sizes: (string, unit) Hashtbl.t;
	 vts: vts;
	 mods: string list;
	 custom: (string, unit) Hashtbl.t;
	 pname: string;
	inarr: bool; (* hack to disable statecalls in arrays *)
    wantsc: bool;
}

exception Internal_error of string

let interr x = raise (Internal_error x)

let dbg = prerr_endline 

let string_of_vt v =
	sprintf "%s (%s)" (String.concat "| " 
	   (List.map (fun (e,i) ->
			sprintf "%s->%s " (string_of_expr e) i
		) v.vt_b)
	)
	(match v.vt_def with |None -> "none" |Some x -> x)

let modname ?(sub=[]) mods =
    let mods = ref (List.rev mods) in
    let sub = List.rev sub in
    assert(List.length sub <= (List.length !mods));
    List.iter (fun x ->
        if List.hd !mods <> x then failwith "modname";
        mods := List.tl !mods;
    ) sub;
    String.concat "." (List.map String.capitalize !mods)

let objname ?(sub=[]) mods =
    sprintf "%s%so" (modname ~sub:sub mods) (if List.length mods > 0 then "." else "")
    
let dump_env env =
    print_endline (sprintf "env=[%s]" (String.concat ", " (List.map (fun (a,b) -> a) env.vars)))

let bind_env env id m =
    {env with vars = (id,m) :: env.vars}

let find_env env id =
    assoc_opt id env.vars

let find_env_statevar env id =
	 match assoc_opt id env.statevars with
	 |None -> None
	 |Some x -> Some (V.S_var (id,None,(V.new_value "statevar" x)))

let map_env_vars env fn =
    let x = List.map (fun (k,v) -> fn k v) env.vars in
    {env with vars=x}

let remap_env_vars env ids fn =
    map_env_vars env (fun k v -> if List.mem k ids then fn k v else (k,v))

let find_bit_vars env uvar =
	 let trunc = ref false in
	 let bvars = List.filter (function (id,v) ->
	   match v with
		|V.S_var (sid,_,(V.Value (_,_,at))) ->
			if sid = uvar then (trunc := true; false) else begin
			 if !trunc then false else at.V.av_bitdummy
			end
		|_ -> false) (List.rev env.vars)
	 in bvars

let remap_bit_depends env uvars =
  (* if any of the uvars are bits, then remap their dependencies too *)
  List.fold_left (fun env uvar ->
	 match find_env env uvar with
	 |Some V.S_var (id,szo,V.Value ("bit",_,at)) ->
		  let bvars = find_bit_vars env uvar in
		  let depvars = List.map (fun (a,_) -> a) (B.bitdeps bvars at.V.av_bitops) in
		  remap_env_vars env depvars (fun vid -> function
			|V.S_var (vid, szo, V.Value (a,b,c)) ->
				let x = V.S_var (vid, szo, V.Value (a,b,{c with V.av_bound=true})) in
				(vid,x)
		   |_ -> interr "var_bind_env"
		  );
	 |_ -> env
    ) env uvars

let var_bind_env env id szo ty =
    let env = match szo with
    |None -> env
    |Some sz -> begin
        let uvars = E.get_variables sz in
		  let env = remap_bit_depends env uvars in
        remap_env_vars env uvars (fun id -> function
            |V.S_var (id, szo, V.Value (a,b,c)) ->
                let x = V.S_var (id, szo, V.Value (a,b,{c with V.av_bound=true})) in
                (id,x)
            |_ -> interr "var_bind_env"
        )
	 end
    in
	 let ty = match ty with
    |V.Value (a,b,({V.av_value=Some _} as c)) -> V.Value(a,b,{c with V.av_bound=true})
	 |x -> x in
    bind_env env id (V.S_var (id,szo,ty))

let class_bind_env env id bid ex =
	 let env = remap_bit_depends env [id] in
    let env = remap_env_vars env [id] (fun id -> function
        |V.S_var (id,szo,V.Value (a,b,({V.av_value=Some _; V.av_bound=true}))) as x ->
            (id,x)
        |V.S_var (id,szo,V.Value (a,b,({V.av_const=None} as c))) ->
            let x = V.S_var (id,szo,V.Value (a,b,{c with V.av_const=Some ex; V.av_bound=true})) in
            (id,x)
        |_ -> interr "class_bind_env") in
    {env with mods=(E.to_const_string bid)::env.mods}

let array_bind_env env id sz =
    let uvars = E.get_variables sz in
    let env = remap_env_vars env uvars (fun id -> function
        |V.S_var (id,szo,V.Value (a,b,c)) ->
            let x = V.S_var (id,szo,V.Value (a,b,{c with V.av_bound=true})) in
            (id,x)
        |_ -> interr "array_bind_env") in
    bind_env env id (V.S_var (id,Some sz,V.Class (id::env.mods)))

let resolve_bits l =
	let bid = ref 0 in
   let rec fn last ac = function
      |V.S_var (id,vsz,ty) as o :: r -> begin
         match ty with
         |V.Value ("bit",V.UInt V.I8,att) ->
             let sz = must E.to_const_int vsz in
				 let ac,ops = B.convert ac sz in
				 let nbytes = List.map (fun num ->
					let nm = sprintf "__bitdummy%d" !bid in
					incr bid;
					V.S_var (nm,None,(V.new_value ~bitdummy:true "byte" (V.UInt V.I8)))
				 ) (B.bitbytes ops) in
             let ac,r = fn (last+(List.length nbytes)) ac r in
				 let o = V.S_var (id,vsz, V.Value("bit",(V.UInt V.I8),{att with V.av_bitops=ops})) in
             ac, (nbytes @ (o :: r))
         |_ ->
             let ac,r = fn last ac r in
             ac, (o :: r)
      end
      |V.S_class (id,ty,l) :: r ->
         let cac = ref 0 in
         let l = List.map (fun (a,b,c,xsc) ->
            let ac,r = fn last ac xsc in
            cac := ac;
            (a,b,c,r)) l in
         let ac,r = fn last !cac r in
         ac,(V.S_class (id,ty,l) :: r)
      |V.S_array (id,sz,xs) :: r ->
         let _,r = fn last ac r in
         let _,r' = fn last ac xs in
         ac, (V.S_array (id,sz,r') :: r)
      |V.S_unit as o :: r ->
         let _,r = fn last ac r in
         ac, (o :: r)
      |[] -> ac,[]
   in
   let _,r = fn 15 0 l in r
      
let make_modules env l = 
    let rec fn l = List.iter (function
        |V.S_var (id,sz,V.Value (_,bty,{V.av_variant=Some l})) ->
            Hashtbl.add env.vts id {vt_ty=bty; vt_b=l; vt_def=None};
        |V.S_var _ -> ()
        |V.S_class (id,ty,l) ->
            List.iter (fun (_,_,_,xs) -> fn xs) l
        |V.S_array (id,sz,xs) ->
            fn xs
        |V.S_unit ->
            ()
    ) l in
    fn l

let get_free_vars env =
    let allids,_ = List.split env.vars in
    assert (allids = (list_unique_s allids));
    let x = List.rev_map (fun (k,v) -> v) env.vars in
    List.rev (List.fold_left (fun a b ->
        match b with
        |V.S_var (id,szo,((V.Value (_,_,{V.av_const=Some _})) as vv))
        |V.S_var (id,szo,((V.Value (_,_,{V.av_bound=true})) as vv))
		  |V.S_var (id,szo,((V.Value (_,_,{V.av_bitdummy=true})) as vv))
        |V.S_var (id,szo,(V.Label as vv)) -> (`Bound (id,szo,vv))::a
        |V.S_var (id,szo,ty) -> (`Free (id,szo,ty)) :: a
		  |_ -> interr "get_free_vars"
    ) [] x)

let get_sentinel_env env unt xs =
	let sentenv = ref None in
	let rec fn env = function
	|V.S_var (id,szo,ty) :: r -> begin
		let env = var_bind_env env id szo ty in
		match ty with
		|V.Label ->
			dbg (sprintf  "sentinel: %s = %s?" unt id);
			if id = unt then begin
				match !sentenv with
				|None -> sentenv := Some env
				|Some _ -> interr "sentinel_env already set"
			end else fn env r
		|_ -> fn env r
	end
	|V.S_class (id,idty,l) :: r ->
		List.iter (fun (ex,bid,gu,xs) ->
			let env = class_bind_env env id bid ex in
			fn env (xs @ r)
		) l
   |V.S_array (id,sz,xs) :: r ->
      let aenv = array_bind_env env id sz in
      let nenv = {aenv with vars=[]; mods=id::env.mods} in
      fn nenv xs;
	   fn aenv r;
   |V.S_unit :: r ->
        fn env r
   |[] -> ()
	in fn env xs;
	match !sentenv with
	|None -> interr "no sentinel found"
	|Some x -> x
	
let get_value_vars env l =
    let rec fn env = function
    |V.S_var (id,szo,ty) :: r -> begin
        let env = var_bind_env env id szo ty in
        fn env r
    end
    |V.S_class (id, idty, l) :: r ->
        List.flatten (List.map (fun (ex,bid,gu,xs) ->
            let env = class_bind_env env id bid ex in
            fn env (xs @ r);
        ) l)
    |V.S_array (id,sz,xs) :: r ->
        let aenv = array_bind_env env id sz in
        let nenv = {aenv with vars=[]; mods=id::env.mods} in
        (fn nenv xs) @ (fn aenv r)
    |V.S_unit :: r->
        fn env r
    |[] ->
        let fvars = get_free_vars env in
        List.fold_left (fun a -> function
            |`Bound (id,szo,(V.Value (_,_,{V.av_bound=true}))) ->
					id :: a
            |_ -> a
        ) [] fvars
    in
	 let ret = list_unique (fn env l) in
	 ret

let get_variant_types env l =
	List.fold_left (fun a -> function
		|V.S_var (id,szo,V.Value (_,bty,{V.av_variant=Some l})) ->
		   (id,{vt_ty=bty; vt_b=l; vt_def=None}) :: a
		|_ -> a
	) [] l

let make_env wsc (tenv,txs) =
    let env = { wantsc=wsc; vars=[]; inarr=false; offsets=tenv.Mpl_typechk.offsets; pname=""; sizes=tenv.Mpl_typechk.sizes; 
		mods=[]; vts=Hashtbl.create 1; statevars=tenv.Mpl_typechk.statevars; custom=tenv.Mpl_typechk.custom} in
	 let txs = resolve_bits txs in
	 make_modules env txs;
	 env,txs
