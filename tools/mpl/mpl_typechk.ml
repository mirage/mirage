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
 * $Id: mpl_typechk.ml,v 1.34 2006/02/16 18:44:39 avsm Exp $
 *)

open Mpl_syntaxtree
open Mpl_utils
open Printf

exception Type_error of string

module L = Mpl_location
module B = Mpl_bits

(* Types for variables *)
module Var = struct
    type isz =
        |I8
        |I16
        |I32
        |I64
        
    (* Base types for statements that target language needs support for *)
    type b =
        |UInt of isz
        |String
        |Bool
        |Opaque

    (* Higher level constructs *)
    type value_attr = {
        mutable av_min: int option;
        mutable av_max: int option;
        mutable av_const: expr option;
        mutable av_value: expr option;
        mutable av_variant: ((expr * string) list) option;
		mutable av_default: expr option;
        mutable av_bitvars: int list;
		mutable av_bitops: B.t list;
        mutable av_bitdummy: bool;
        av_bound: bool;
    }
    
    type array_attr = {
        mutable aa_align: int option;
    }
    
    type t =
        |Packet of (string * (string list))
        |Value of (string * b * value_attr)
        |Array of (string * b * array_attr)
        |Class of string list
        |Label

    type x =
    | S_var of (id * expr option * t)   (* id,size,type *)
    | S_class of (id * b * (expr * expr * expr option * xs) list) (* id,ty,(match,label,guard,xs) *)
    | S_array of (id * expr * xs) (* id,int size,xs *)
    | S_unit
    and xs = x list

    let new_value ?(bitdummy=false) vty v =
        Value (vty, v, {av_min=None; av_max=None; av_const=None; av_value=None;
            av_variant=None; av_bound=false; av_bitvars=[]; av_bitdummy=bitdummy;
				av_bitops=[]; av_default=None})
   
    let new_array vty v =
        Array (vty, v, {aa_align=None})

    let to_string =
        let so fn = function |None -> "N" |Some x -> fn x in
        let soe = so string_of_expr in
        let soi = so string_of_int in
        let sov = so (fun x -> String.concat ", " (List.map (fun (a,b) ->
            sprintf "%s->%s" (string_of_expr a) b) x)) in
        let fn = function
        |UInt I8 -> "byte"
        |UInt I16 -> "uint16"
        |UInt I32 -> "uint32"
        |UInt I64 -> "uint64"
        |String -> "string"
        |Bool -> "bool"
        |Opaque -> "opaque"
        in function
        |Packet (id,args) ->
            sprintf "Packet(%s: %s)" id (String.concat "," args)
        |Value (vty,b,a) ->
            sprintf "Value(%s:%s) [Mn:%s Mx:%s C:%s Vl:%s Vx:%s BV:%s BO:%s BD:%s]" (fn b) vty
             (soi a.av_min) (soi a.av_max) (soe a.av_const) (soe a.av_value)
             (sov a.av_variant) (String.concat "," (List.map string_of_int a.av_bitvars)) ""
             (if a.av_bitdummy then "Y" else "N")
        |Array (vty,b,a) -> sprintf "Array(%s:%s) [Align:%s]" (fn b) vty (soi a.aa_align)
        |Class x -> sprintf "Class(%s)" (String.concat "" x)
        |Label -> sprintf "Label"
    
    open Printer_utils.Printer
    let rec print_x e = function
    |S_var (id,exo,t) :: r->
        let s = match exo with |None -> "" |Some x -> sprintf "[%s]" (string_of_expr x) in
        e.p (sprintf "Var (%s%s): %s" id s (to_string t));
        print_x e r
    |S_class (id,idty,l) :: r ->
        e.p (sprintf "Class (%s): %s" id (to_string (new_value "xxx" idty)));
        list_iter_indent e (fun e (ex,id,guard,sts) ->
            let g = match guard with |None -> ""| Some e -> sprintf "when %s " (string_of_expr e) in
            e.p (sprintf "| %s:%s %s->" (string_of_expr ex) (string_of_expr id) g);
            print_x e sts;
        ) l;
        print_x e r
    |S_unit :: r -> e.p "Unit"; print_x e r
    |S_array (id, sz, xs) :: r ->
        e.p (sprintf "Array (%s)" id); print_x e r
    |[] -> ()
    
end

(* Type checking environment *)
type env = {
	 t_sdefs: (string, statements) Hashtbl.t;
	 t_tdefs: (string, (L.t * string)) Hashtbl.t;
    root: Mpl_syntaxtree.packet;
    statevars: (string * Var.b) list;
    vars: (string * Var.t) list;
    bit_accum: int;
    sizes: (id, unit) Hashtbl.t;
    offsets: (id, unit) Hashtbl.t;
    custom: (id, unit) Hashtbl.t;
}

let log = Logger.log_verbose

let bind_var env id ty =
    {env with vars=(id,ty)::env.vars}

let get_var_type env id =
    assoc_opt id env.vars

let bind_accum env a =
    {env with bit_accum=(env.bit_accum+a) mod 8}	
    
let bind_reset_accum env =
    {env with bit_accum=0}

let dump_env env =
    log (sprintf "[tenv] {%s} acc=%d" (String.concat ", "
        (List.map (fun (a,b) ->
            sprintf "%s:%s" a (Var.to_string b)) env.vars)) env.bit_accum)

(* Types for expressions *)
module Expr = struct
    type t = 
        |Int
        |String
        |Bool
    
    let to_string = function
        |Int -> "int"
        |String -> "string"
        |Bool -> "bool"

    type fdef = {
        fname: string;
        fret: t;
        fargs: t list;
    }

    let builtin_funcs = [
        {fname="offset"; fret=Int; fargs=[String]};
        {fname="sizeof"; fret=Int; fargs=[String]};
        {fname="remaining"; fret=Int; fargs=[]};
    ]

    let rec typeof ?(unmarshal=false) (env:env) =
        let terr x = raise (Type_error (sprintf "expr: %s" x)) in
        let tmatch (ext:t) l =
            let err ex ety =
                terr (sprintf "expecting type %s, got type %s (%s)"
                    (to_string ext) (string_of_expr ex) (to_string ety)) in
            List.iter (fun x -> let tx = typeof ~unmarshal:unmarshal env x in if tx <> ext then err x tx) l
        in function
        |True -> Bool
        |False -> Bool
        |String_constant _ -> String
        |Int_constant _ -> Int
        |Range (a,b) -> tmatch Int [a;b]; Int
        |And (a,b) -> tmatch Bool [a;b]; Bool
        |Or (a,b) -> tmatch Bool [a;b]; Bool
        |Not a -> tmatch Bool [a]; Bool
        |Greater (a,b) -> tmatch Int [a;b]; Bool
        |Less (a,b) -> tmatch Int [a;b]; Bool
        |Greater_or_equal (a,b) -> tmatch Int [a;b]; Bool
        |Less_or_equal (a,b) -> tmatch Int [a;b]; Bool
        |Equals (a,b) -> tmatch Int [a;b]; Bool
        |Plus (a,b) -> tmatch Int [a;b]; Int
        |Minus (a,b) -> tmatch Int [a;b]; Int
        |Multiply (a,b) -> tmatch Int [a;b]; Int
        |Divide (a,b) -> tmatch Int [a;b]; Int
        |Function_call (nm, arg) -> begin
            let targ nm =
                terr (sprintf "Function '%s' requires argument" nm) in
            match nm,arg with
            |"offset",Some v -> begin
                Hashtbl.replace env.offsets v ();
                match get_var_type env v with
                |None when unmarshal -> terr (sprintf "Unknown variable '%s' in offset()" v) 
                |None -> Int  (* XXX we check values later *)
                |Some id -> Int
            end
            |"offset",None -> targ "offset"
            |"sizeof",Some v -> begin
                Hashtbl.replace env.sizes v (); 
                match get_var_type env v with
                |None when unmarshal -> terr (sprintf "Unknown variable '%s' in sizeof()" v)
                |None -> Int
                |Some id -> Int
            end
            |"array_length",None -> targ "array_length"
            |"array_length",Some v -> begin
                Int
            end
            |"sizeof",None -> targ "sizeof"
            |"remaining",None ->
                Int;
            |"remaining",Some _ ->
                terr ("Function 'remaining()' should  not have any arguments")
            |_,_ -> terr (sprintf "Unknown function '%s'" nm)
        end
        |Identifier id -> begin
            let module V = Var in
            match get_var_type env id with
            |Some V.Value(vty,V.UInt _,_) -> Int
            |Some x ->
                terr (sprintf "identifier %s has non-integer type %s" id (Var.to_string x))
            |None ->
                terr (sprintf "unknown variable %s" id)
        end

    let rec typeof_statevar (env:env) =
        let terr x = raise (Type_error (sprintf "statevar: %s" x)) in
        let tmatch (ext:t) l =
            let err ex ety =
                terr (sprintf "expecting type %s, got type %s (%s)"
                    (to_string ext) (to_string ety) (string_of_expr ex)) in
            List.iter (fun x -> let tx = typeof_statevar env x in if tx <> ext then err x tx) l
        in function
        |True -> Bool
        |False -> Bool
        |String_constant _ -> String
        |Int_constant _ -> Int
        |Range (a,b) -> terr "Ranges not allowed in classify guards"
        |And (a,b) -> tmatch Bool [a;b]; Bool
        |Or (a,b) -> tmatch Bool [a;b]; Bool
        |Not a -> tmatch Bool [a]; Bool
        |Greater (a,b) -> tmatch Int [a;b]; Bool
        |Less (a,b) -> tmatch Int [a;b]; Bool
        |Greater_or_equal (a,b) -> tmatch Int [a;b]; Bool
        |Less_or_equal (a,b) -> tmatch Int [a;b]; Bool
        |Equals (a,b) -> tmatch Int [a;b]; Bool
        |Plus (a,b) -> tmatch Int [a;b]; Int
        |Minus (a,b) -> tmatch Int [a;b]; Int
        |Multiply (a,b) -> tmatch Int [a;b]; Int
        |Divide (a,b) -> tmatch Int [a;b]; Int
        |Function_call (nm, arg) -> terr "Function calls not allowed in classify guards"
        |Identifier id -> begin
            let module V = Var in
            match assoc_opt id env.statevars with
            |Some (V.UInt _) -> Int
            |Some V.Bool -> Bool
            |Some _ -> terr "internal error: typeof_statevar"
            |None -> terr (sprintf "unknown state variable '%s'" id)
        end

    (* Ensure expression is a constant *)
    let check_const e =
        let rec fn = function
        |True -> true
        |False -> true
        |String_constant _ -> true
        |Int_constant _ -> true
        |Range (a,b) -> false
        |And (a,b) -> fn2 a b
        |Or (a,b) -> fn2 a b
        |Not a -> fn a
        |Greater (a,b) -> fn2 a b
        |Less (a,b) -> fn2 a b
        |Greater_or_equal (a,b) -> fn2 a b
        |Less_or_equal (a,b) -> fn2 a b
        |Equals (a,b) -> fn2 a b
        |Plus (a,b) -> fn2 a b
        |Minus (a,b) -> fn2 a b
        |Multiply (a,b) -> fn2 a b
        |Divide (a,b) -> fn2 a b
        |Function_call _ -> false
        |Identifier _ -> false
        and fn2 a b = (fn a) && (fn b) in
        if not (fn e) then
            raise (Type_error (sprintf "expr '%s' is not constant"
                (string_of_expr e)))

    let is_const e =
		  try check_const e; true with
		  Type_error _ -> false

    (* Convert expression to a constant int *)
    let to_const_int e =
        let terr e = raise (Type_error 
                (sprintf "int_expr_fold: unable to constant fold (%s) to type int"
                    (string_of_expr e))) in
        let rec fn = function
        |Int_constant x -> x
        |Range _ as e -> terr e
        |Plus (a,b) -> (fn a) + (fn b)
        |Minus (a,b) -> (fn a) - (fn b)
        |Multiply (a,b) -> (fn a) * (fn b)
        |Divide (a,b) -> (fn a) / (fn b)
        |_ as e -> terr e
        in
        fn e
        
    (* Convert expression to a constant string *)
    let to_const_string e =
        let terr e = raise (Type_error 
                (sprintf "string_expr_fold: unable to constant fold (%s) to type string"
                    (string_of_expr e))) in
        let rec fn = function
        |String_constant x -> x
        |_ as e -> terr e
        in fn e
        
    (* Extract a list of variable identifiers from an expression *)
    let get_variables =
        let rec fn acc = function
        |Identifier id -> id :: acc
        |Range (a,b) -> fn2 acc a b
        |And (a,b) -> fn2 acc a b
        |Or (a,b) -> fn2 acc a b
        |Not a -> fn acc a
        |Greater (a,b) -> fn2 acc a b
        |Less (a,b) -> fn2 acc a b
        |Greater_or_equal (a,b) -> fn2 acc a b
        |Less_or_equal (a,b) -> fn2 acc a b
        |Equals (a,b) -> fn2 acc a b
        |Plus (a,b) -> fn2 acc a b
        |Minus (a,b) -> fn2 acc a b
        |Multiply (a,b) -> fn2 acc a b
        |Divide (a,b) -> fn2 acc a b
        |Function_call _ |String_constant _ |Int_constant _
        |True | False -> acc
        and fn2 acc a b = let acc' = fn acc a in fn acc' b
        in fn []
        
    let get_functions n fnn =
        let rec fn acc = function
        |Function_call (nm,argo) ->
            if n = nm then (fnn argo) :: acc else acc
        |Range (a,b) -> fn2 acc a b
        |And (a,b) -> fn2 acc a b
        |Or (a,b) -> fn2 acc a b
        |Not a -> fn acc a
        |Greater (a,b) -> fn2 acc a b
        |Less (a,b) -> fn2 acc a b
        |Greater_or_equal (a,b) -> fn2 acc a b
        |Less_or_equal (a,b) -> fn2 acc a b
        |Equals (a,b) -> fn2 acc a b
        |Plus (a,b) -> fn2 acc a b
        |Minus (a,b) -> fn2 acc a b
        |Multiply (a,b) -> fn2 acc a b
        |Divide (a,b) -> fn2 acc a b
        |Identifier _ |String_constant _ |Int_constant _
        |True | False -> acc
        and fn2 acc a b = let acc' = fn acc a in fn acc' b
        in fn []
        
    let get_sizeof =
        get_functions "sizeof" (must (fun x -> x))
        
    let get_offset =
        get_functions "offset" (must (fun x -> x))
        
end

module E = Expr
module V = Var

module Types = struct
    (* Mapping of user-exposed types to our basic types. Different user-exposed
       types may have different packing formats, but _must_ map onto one of the
       basic types indicated above.  The backend will transform these basic types
       into the desired language (e.g. C/Java/OCaml/Python) *)
    let of_string = function
        |"string8"|"string32" -> Some V.String
        |"mpint" -> Some V.Opaque
        |"bit"|"byte" -> Some (V.UInt V.I8)
        |"uint16" -> Some (V.UInt V.I16)
        |"uint32" -> Some (V.UInt V.I32)
        |"uint64" -> Some (V.UInt V.I64)
        |"boolean" -> Some V.Bool
        |"dns_label"|"dns_label_comp" -> Some V.Opaque
        |_ -> None

    let is_custom = function
        |"bit"|"byte"|"uint16"|"uint32"|"uint64" -> false
        |_ -> true
end

module T = Types

(* Unmarshalling type checking *)
let rec typeof env (xs:statements) : (env * Var.xs) =
    let env,xs = List.fold_left (fun (env,axs) (loc,s) ->
        let terr x = raise (Type_error (sprintf "statement%s %s"
            (Mpl_location.string_of_location loc) x)) in
        (* Mark a variable as not being free any more *)
        let tdup env x = match get_var_type env x with
        |None -> () |Some _ -> terr (sprintf "Duplicate variable '%s'" x) in
        let check_bit_accum env =
            if env.bit_accum mod 8 != 0 then
                terr (sprintf "Bit-fields must be byte-aligned, but ends on %d bits"
                    env.bit_accum);
            bind_reset_accum env;
        in
        let renv, rxs = match s with
        |Unit ->
            env, V.S_unit
        |Packet (id, pmod, args) ->
            tdup env id;
            (* XXX check that the pmod and args are valid, needs external interface files *)
            env, (V.S_var (id, None, V.Packet ((String.capitalize pmod), args)))
        |Variable (id, ty, sz, attrs) -> begin
            (* First make sure variable hasn't already been bound *)
            tdup env id;
            (* Figure out the variable's type *)
            let varty =
                match (ty,sz) with
                |"label", Some _ ->
                    terr "label types cannot be arrays"
                |"label", None ->
                    if List.length attrs > 0 then
                        terr "label types cannot have attributes";
                    V.Label
                |t, None -> begin
                    if ty = "bit" then terr "Bit fields must specify a size";
                    let tty = match T.of_string t with
                    |None -> terr ("unknown type " ^ t)
                    |Some x -> x in
                    if T.is_custom t then Hashtbl.replace env.custom t ();
                    V.new_value ty tty
                end
                |t, Some sz -> begin
                    (* ensure array size is of type int *)
                    let _ = try
                    if E.typeof ~unmarshal:true env sz <> E.Int then
                        terr (sprintf "Array size (%s) is not an integer type" (string_of_expr sz));
                    with Type_error x -> terr x in
                    match (t, T.of_string t) with
                    |"bit", Some x ->
                        let szi = E.to_const_int sz in
								if szi < 1 then
									 terr (sprintf "Bitfield size %d is too small, min 1" szi);
                        if szi > 15 then 
                            terr (sprintf "Bitfield size %d is too long, max 15" szi);
                        V.new_value ty x
                    |_, None -> terr ("unknown type " ^ t)
                    |_, Some x -> begin
                        let avs = E.get_variables sz in
                        List.iter (fun vid -> match get_var_type env vid with
                            |None -> terr ("typeof: " ^ id);
                            |Some (V.Value (_,_,{V.av_bound=true})) 
                            |Some (V.Value (_,_,{V.av_value=Some _})) ->
                                ()
                            |_ ->
                                terr (sprintf "Variable '%s' must have a value attribute to tie it to '%s'" vid id)
                        ) avs;
                        Var.new_array ty x
                    end
                end;
            in
            (* Check variable attributes *)
            let varty = List.fold_left (fun varty attr -> match varty,attr with
	         |V.Packet _ as o, _ -> o
            |V.Class _, _ ->
                terr "Internal error, V.Class"
            |V.Label, _ ->
                terr "Label types cannot have attributes"
            |V.Array (_,_, {V.aa_align=Some _}), Align e ->
                terr "Duplicate attribute 'align'"
            |V.Value (_,_, {V.av_min=Some _}), Min e ->
                terr "Duplicate attribute 'min'"
            |V.Value (_,_, {V.av_max=Some _}), Max e ->
                terr "Duplicate attribute 'max'"
            |V.Value (_,_, {V.av_const=Some _}), Const e ->
                terr "Duplicate attribute 'const'"
            |V.Value (_,_, {V.av_value=Some _}), Value e ->
                terr "Duplicate attribute 'value'"
				|V.Value (_,_, {V.av_default=Some _}), Default e ->
					 terr "Duplicate attribute 'default'"
            |V.Array (_,V.UInt V.I8, ({V.aa_align=None} as a)) as o, Align e ->
                a.V.aa_align <- Some (E.to_const_int e); o
            |V.Array _, _ ->
                terr "This attribute is not compatible with array variables"
            |_, Align _ ->
                terr "Attribute 'align' not valid except with arrays"
            |V.Value (_,V.UInt _, ({V.av_min=None} as a)) as o, Min e ->
                a.V.av_min <- Some (E.to_const_int e); o
            |V.Value _, Min e ->
                terr "Attribute 'min' must be used with int variables"                
            |V.Value (_,V.UInt _, ({V.av_max=None} as a)) as o, Max e ->
                a.V.av_max <- Some (E.to_const_int e); o
            |V.Value _, Max e ->
                terr "Attribute 'max' must be used with int variables"
            |V.Value (_,vt, ({V.av_value=None} as a)) as o, Value e ->
                let () = match (E.typeof env e), vt with
                |E.Int, V.UInt _
                |E.String, V.String
                |E.Bool, V.Bool -> ()
                |_ as b,_ -> terr (sprintf "Attribute 'value' types dont match (%s and %s)"
                    (E.to_string b) (V.to_string o)) in
                a.V.av_value <- Some e; o
            |V.Value (_,vt, ({V.av_default=None} as a)) as o, Default e -> begin
                E.check_const e;
                let () = match (E.typeof env e), vt with
                |E.Int, V.UInt _
                |E.String, V.String
                |E.Bool, V.Bool -> ()
                |_ as b,_ -> terr (sprintf "Attribute 'default' types dont match (%s and %s)"
                    (E.to_string b) (V.to_string o)) in
                a.V.av_default <- Some e;
                o
            end
            |V.Value (_,vt, ({V.av_const=None} as a)) as o, Const e -> begin
                E.check_const e;
                let () = match (E.typeof env e), vt with
                |E.Int, V.UInt _
                |E.String, V.String
                |E.Bool, V.Bool -> ()
                |_ as b,_ -> terr (sprintf "Attribute 'const' types dont match (%s and %s)"
                    (E.to_string b) (V.to_string o)) in
                a.V.av_const <- Some e;
                o
            end
            |V.Value (vty,vt, ({V.av_min=None; av_max=None; av_const=None; av_value=None; av_variant=None} as a)) as o, Variant (x,def) -> begin
                let h = Hashtbl.create 1 in
                List.iter (fun (m,r) ->
                    (* Variant tag Unknown is reserved *)
                    if String.lowercase r = "unknown" then
                        terr "Variant tag 'Unknown' is reserved";
                    (* All variant matches must be constants and the strings unique *)
                    let _ = if Hashtbl.mem h r then
                        terr (sprintf "Variant match '%s' is duplicated" r)
                    else
                        Hashtbl.add h r () in
                    E.check_const m;
                    match (E.typeof env m), vt with
                    |E.Int, V.UInt _
                    |E.String, V.String
                    |E.Bool, V.Bool -> ()
                    |_ as b,_ -> terr (sprintf 
                        "Attribute 'variant' matches must all have type '%s', not '%s'"
                            (V.to_string o) (E.to_string b))
                ) x;
                a.V.av_variant <- Some x;
					 a.V.av_default <- def;
                o
            end
            |_ as a, Variant _ ->
                terr (sprintf "Cannot mix attribute 'variant' with other attributes (%s)" (V.to_string a))
            ) varty attrs in
            (* Record variable in the environment *)
            let env = bind_var env id varty in
            (* Check bit alignments *)
            let env = match (ty,sz) with
                |"bit", Some sz ->
                    let env = bind_accum env (Expr.to_const_int sz) in
                    env
                |_ ->
                    check_bit_accum env
            in
            let vr = V.S_var (id, sz, varty) in
            env, vr
        end
        |Array (id, sz, sts) ->
            (* Check we are on a byte boundary *)
            let env = check_bit_accum env in
            (* Make sure the id is unique *)
            tdup env id;
            (* Just bind the id as a Label in our environment to reserve the name *)
            let env = bind_var env id V.Label in
            (* Check that the array size expression is an Int *)
            let _ = match Expr.typeof env sz with
            |E.Int -> ()
            |_ -> terr (sprintf "Array size (%s) is not of type int" (string_of_expr sz))
            in
            (* Check that the vars used in the size expr have associated values *)
            List.iter (fun var ->
                match get_var_type env var with
                |None -> terr "internal error: no type for var in Array"
                |Some (V.Value (_,_, {V.av_value=None})) ->
                    terr (sprintf "Must specify 'value' attribute for variable '%s'" var)
                |Some (V.Value (_,_, ({V.av_max=Some _}|{V.av_const=Some _}|{V.av_min=Some _}))) ->
                    terr (sprintf "Cannot have attributes min/max/const on variables referenced in array sizes")
                |Some _ -> ()
            ) (E.get_variables sz);
            let aenv,vrxs = typeof env sts in
            (* Check that the array block is bit aligned *)
            let _ = check_bit_accum aenv in
            (* Return original env, not the array statement env! *)
            let vr = V.S_array (id, sz, vrxs) in
            env, vr
        |Classify (id, l) -> begin
            (* Make sure that the classified identifier exists *)
            let idty = match get_var_type env id with
            |None -> terr (sprintf "Variable '%s' unknown for classification" id)
            |Some (V.Value (_,_, {V.av_bound=true})) ->
                terr "Classify variable has already been previously bound to another classify";
(*            |Some (V.Value (_,_, {V.av_value=Some _})) ->
                terr "Classify cannot bind to a variable with a 'value' attribute" *)
            |Some (V.Value (_,_, ({V.av_max=Some _}|{V.av_const=Some _}|{V.av_min=Some _}))) ->
                terr (sprintf "Cannot have attributes min/max/const on classified variables")
            |Some ty -> ty in
            (* No permanent variables are recorded in a classification right now *)
            (* Remap the classified variable as bound *)
            let envv = List.fold_left (fun a (i,b) ->
                let x = match b with
                |V.Value (vid,sz,at) as o ->
                    if id = i then V.Value (vid,sz,{at with V.av_bound=true})
                    else o
                |o -> o
                in
                (i,x) :: a  
            ) [] env.vars in
            let env = {env with vars=envv} in
            let cenvs,cxs = List.split (List.fold_left (fun a (ex,id,guard,xs) ->
                may (fun g ->
                    let gt = E.typeof_statevar env g in 
                    match gt with
                    |E.Bool -> ()
                    |_ -> terr (sprintf "Classify guard '%s' must be of type bool" (string_of_expr g))) guard;
                let exty = E.typeof env ex in
                let _ = match (idty, exty) with
                |V.Class _,_ -> terr ("internal error, V.Class")
                |V.Value(_,V.UInt _, _), E.Int
                |V.Value(_,V.String, _), E.String
                |V.Value(_,V.Bool, _), E.Bool
                    -> true
                |V.Packet _, _
                |V.Value(_), _
                |V.Array(_), _
                |V.Label, _
                    -> terr (sprintf "Classify type (%s) does not match expression (%s)"
                        (Var.to_string idty) (string_of_expr ex))
                in
                let e,x = typeof env xs in
                let x = (ex,id,guard,x) in
                (e,x) :: a
            ) [] l) in
            (* Check that all sub-environments are equally bit-aligned *)
				let acl = list_unique (List.map (fun e -> e.bit_accum) cenvs) in
				let ac = if List.length acl > 1 then terr (sprintf "Classify elements are not equally bit-aligned (%s)"
					(String.concat "," (List.map string_of_int acl))) else List.hd acl in
            (* Add the bit alignments to the environment, but no variables are bound *)
            let idty' = match idty with |V.Value (_,x,_) -> x |_ -> terr "idty" in
            let vr = V.S_class (id,idty', cxs) in
            {env with bit_accum=ac}, vr
        end in
        renv, (rxs::axs)
    ) (env,[]) xs in
    env, (List.rev xs)

let resolve_defs env xs =
	 (* all ids must be unique *)
	 (* XXX TODO check for overlapping typedef/structs, and that struct statements 
		 only contain basic Variables with no external references *)
	 let nm = Hashtbl.create 1 in
	 Hashtbl.iter (fun id (loc,t) ->
		  prerr_endline (sprintf "[dbg] typedef %s -> %s" id t);
	     if Hashtbl.mem nm id then raise
		      (Type_error (sprintf "%s duplicate typedef %s" (L.string_of_location loc) id));
		  Hashtbl.add nm id ();
		  match T.of_string t with
		  |None -> raise (Type_error (sprintf "%s unknown basic type %s for typedef %s" (L.string_of_location loc) t id))
		  |Some _ -> ()
	 ) env.t_tdefs;
	 let rec fn = function
	  | (loc,Variable (id,ty,ex,at)) as o :: r ->
		 if Hashtbl.mem env.t_tdefs ty then begin
			let _,t = Hashtbl.find env.t_tdefs ty in
			(loc,Variable (id,t,ex,at)) :: (fn r)
		 end else begin
		     if Hashtbl.mem env.t_sdefs ty then begin
		         let xst = Hashtbl.find env.t_sdefs ty in
		         let xst = List.map (fun (_,x) -> match x with
		            |Variable (vid,t,ex,at) ->
		                (loc, Variable ((id ^ "_" ^ vid), t, ex, at))
		            |_ -> raise (Type_error (sprintf "struct %s contains non-variable entry" ty))
		         ) xst in
		         xst @ (fn r)
		     end else
		         o :: (fn r)
		 end
	  | (loc,Classify (id, l)) :: r ->
	    let l = List.map (fun (a,b,c,xsc) -> (a,b,c,(fn xsc))) l in
	    (loc,Classify (id,l)) :: (fn r)
	  | (loc,Array (id, ex, xsa)) :: r -> (loc,Array (id, ex, (fn xsa))) :: (fn r)
	  | (loc, Packet _) as o :: r -> o :: (fn r)
	  | (loc,Unit) :: r -> (loc,Unit) :: (fn r)
	  | [] -> [] in
	 fn xs
	
let typecheck ps =
	 (* send this environment to each packet *)
	 List.map (fun packet ->
	    let terr x = raise (Type_error (sprintf "packet %s%s %s" packet.name
	        (L.string_of_location packet.loc) x)) in
	    let h = Hashtbl.create 1 in
	    List.iter (fun b ->
	        let id,ty = match b with
	        |P_bool id -> id, Var.Bool
	        |P_int id -> id, Var.UInt Var.I8
	        in if Hashtbl.mem h id then terr (sprintf "Duplicate state variable '%s'" id)
	        else Hashtbl.add h id ty) packet.args;
	    let svars = Hashtbl.fold (fun k v a -> (k,v) :: a) h [] in
	    let env = {root=packet; statevars=svars; vars=[]; bit_accum=0; sizes=Hashtbl.create 1; offsets=Hashtbl.create 1;
		            t_tdefs=ps.tdefs; t_sdefs=ps.sdefs; custom=Hashtbl.create 1} in
	    typeof env (resolve_defs env packet.body)
	 ) ps.pdefs
