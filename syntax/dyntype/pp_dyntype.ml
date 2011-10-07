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

(* Type generator *)

open Camlp4
open PreCast
open Ast

open Dyntype

let expr_list_of_list _loc exprs =
	match List.rev exprs with
	| []   -> <:expr< [] >>
	| h::t ->
    List.fold_left (fun accu x -> <:expr< [ $x$ :: $accu$ ] >>) <:expr< [ $h$ ] >> t 

let type_of t = "type_of_" ^ t

let split str sep =
  let rec split_rec pos =
    if pos >= String.length str then [] else begin
      try
        let newpos = String.index_from str pos sep in
        String.sub str pos (newpos - pos) :: split_rec (newpos + 1)
      with Not_found ->
        [String.sub str pos (String.length str - pos)]
    end in
  split_rec 0

let gen_ident _loc gen t =
  match List.rev (split t '.') with
  | []               -> assert false
  | [m]              -> <:expr< $lid:gen m$ >>
  | last :: rev_rest ->
    let id_last = gen last in
    let id_rev_rest = List.map (fun x -> <:ident< $uid:x$ >>) rev_rest in
    <:expr< $id:Ast.idAcc_of_list (List.rev id_rev_rest)$.$lid:id_last$ >>

let list_of_ctyp_decl tds =
  let rec aux accu = function
  | Ast.TyAnd (loc, tyl, tyr)      -> aux (aux accu tyl) tyr
  | Ast.TyDcl (loc, id, _, ty, []) -> (loc, id, ty) :: accu
  | _                               ->  failwith "list_of_ctyp_decl: unexpected type"
  in aux [] tds

let type_not_supported ctyp =
  let module PP = Camlp4.Printers.OCaml.Make(Syntax) in
  let pp = new PP.printer () in
  Format.eprintf "Type %a@. not supported\n" pp#ctyp ctyp;
  failwith "type not supported by DynType"

let append _loc modules id =
  let rec aux = function
    | <:ident< $uid:n$>>      -> [n]
    | <:ident< $m$.$uid:n$ >> -> n :: aux m
    | _ -> assert false in
  String.concat "." (List.rev (id :: aux modules))

let list_of_fields fn fields =
  let rec aux accu = function
    | <:ctyp< $t1$; $t2$ >>             -> aux (aux accu t2) t1
    | <:ctyp< $lid:id$ : mutable $t$ >> -> (id, `RW, fn t) :: accu
    | <:ctyp< $lid:id$ : $t$ >>         -> (id, `RO, fn t) :: accu
    | _                                 -> failwith "unexpected AST" in
  aux [] fields

let list_of_sum fn variants =
  let rec aux accu = function
    | <:ctyp< $t1$ | $t2$ >>     -> aux (aux accu t2) t1
    | <:ctyp< `$uid:id$ of $t$ >>
    | <:ctyp< $uid:id$ of $t$ >> -> (id, List.map fn (list_of_ctyp t [])) :: accu
    | <:ctyp< `$uid:id$ >>
    | <:ctyp< $uid:id$ >>        -> (id, []) :: accu
    | _ -> failwith "unexpected AST" in
  aux [] variants

let rec is_polymorphic = function
  | <:ctyp< $t1$ | $t2$ >>    -> is_polymorphic t1 || is_polymorphic t2
  | <:ctyp< `$uid:_$ of $_$ >>
  | <:ctyp< `$uid:_$ >>        -> true
  | <:ctyp< $uid:_$ of $_$ >>
  | <:ctyp< $uid:_$ >>        -> false
  | _ -> assert false

(* For each type declaration in tds, returns the corresponding unrolled Type.t.  *)
(* The remaining free variables in the type corresponds to external type         *)
(* declarations.                                                                 *)
let create tds : (loc * string * t) list =
  let bind v t = if List.mem v (free_vars t) then Rec (v, t) else Ext (v, t) in
  let tablefn = Hashtbl.create 16 in
  let register name fn = Hashtbl.replace tablefn name fn in
  let apply name arg = bind name ((Hashtbl.find tablefn name) arg) in
  let exists name = Hashtbl.mem tablefn name in

  let rec aux bound_vars ctyp =
    let same_aux = aux (bound_vars) in
    match ctyp with
    | <:ctyp< unit >>         -> Unit
    | <:ctyp< int >>          -> Int (Some (Sys.word_size - 1))
    | <:ctyp< int32 >>        -> Int (Some 32)
    | <:ctyp< int64 >>        -> Int (Some 64)
    | <:ctyp< float >>        -> Float
    | <:ctyp< bool >>         -> Bool
    | <:ctyp< char >>         -> Char
    | <:ctyp< string >>       -> String
    | <:ctyp< option $ty$ >>  -> Option (same_aux ty)
    | <:ctyp< ( $tup:tp$ ) >> -> Tuple (List.map same_aux (list_of_ctyp tp []))
    | <:ctyp< list $ctyp$ >>  -> List (same_aux ctyp)
    | <:ctyp< array $ctyp$ >> -> Array (same_aux ctyp)
    | <:ctyp< [< $variants$] >> 
    | <:ctyp< [> $variants$] >>
    | <:ctyp< [= $variants$] >> 
    | <:ctyp< [$variants$] >> ->
      let kind = if is_polymorphic variants then `P else `N in
      Sum (kind, list_of_sum same_aux variants)
    | <:ctyp< { $fields$ } >> -> Dict (`R, list_of_fields same_aux fields)
    | <:ctyp< < $fields$ > >> -> Dict (`O, list_of_fields same_aux fields)
	  | <:ctyp< $t$ -> $u$ >>   -> Arrow (same_aux t, same_aux u)
    | <:ctyp< $lid:id$ >> when not (exists id) || List.mem id bound_vars
                              -> Var id
    | <:ctyp< $lid:id$ >>     -> apply id (id :: bound_vars)
    | <:ctyp@loc< $id:m$.$lid:id$ >> -> Var (append loc m id)
    | x                       -> type_not_supported x in

  let ctyps = list_of_ctyp_decl tds in
  List.iter
    (fun (loc, name, ctyp) -> register name (fun bound_vars -> aux bound_vars ctyp))
    ctyps;
  List.map (fun (loc, name, ctyp) -> loc, name, apply name [name]) ctyps

let meta_field _loc fn = function
  | (n, `RW, t) -> <:expr< ($str:n$, `RW, $fn t$) >>
  | (n, `RO, t) -> <:expr< ($str:n$, `RO, $fn t$) >>

let meta_dict _loc fn (t,tl) =
  let kind = match t with `R -> <:expr< `R >> | `O -> <:expr< `O >> in
  let tl = List.map (meta_field _loc fn) tl in
  match t with
  | `R -> <:expr< T.Dict $kind$ $expr_list_of_list _loc tl$ >>
  | `O -> <:expr< T.Dict $kind$ $expr_list_of_list _loc tl$ >>

let meta_variant _loc fn (n, tl) =
  let tl = List.map fn tl in
  <:expr< ($str:n$, $expr_list_of_list _loc tl$) >>

let meta_sum _loc fn (t,ts) =
  let kind = match t with `P -> <:expr< `P >> | `N -> <:expr< `N >> in
  let ts = List.map (meta_variant _loc fn) ts in
  <:expr< T.Sum $kind$ $expr_list_of_list _loc ts$ >>

let meta_tuple _loc fn tl =
  let tl = List.map fn tl in
  <:expr< T.Tuple $expr_list_of_list _loc tl$ >>

let gen tds =
  let _loc = loc_of_ctyp tds in
  let types = create tds in
  let subst_external_var (_loc, name, t) =
    let freev = free_vars t in
    let rec aux = function
    | Var v when List.mem v freev
                 -> <:expr< $gen_ident _loc type_of v$ >>
    | Var v      -> <:expr< T.Var $str:v$ >>
    | Rec (v, t) -> <:expr< T.Rec $str:v$ $aux t$ >>
    | Ext (v, t) -> <:expr< T.Ext $str:v$ $aux t$ >>
    | Unit       -> <:expr< T.Unit >>
    | Int None   -> <:expr< T.Int None >>
    | Int(Some n)-> <:expr< T.Int (Some $`int:n$) >>
    | Float      -> <:expr< T.Float >>
    | Bool       -> <:expr< T.Bool >>
    | Char       -> <:expr< T.Char >>
    | String     -> <:expr< T.String >>
    | Option t   -> <:expr< T.Option $aux t$ >>
    | Tuple tl   -> meta_tuple _loc aux tl
    | List t     -> <:expr< T.List $aux t$ >>
    | Array t    -> <:expr< T.Array $aux t$ >>
    | Sum (t,ts) -> meta_sum _loc aux (t,ts)
    | Dict(t,ts) -> meta_dict _loc aux (t,ts)
    | Arrow(t,s) -> <:expr< T.Arrow $aux t$ $aux s$ >>
    in
    <:binding< $lid:type_of name$ = let module T = Type in $aux t$ >>
  in
  let bindings = List.map subst_external_var types in
  <:str_item< value $biAnd_of_list bindings$ >>
