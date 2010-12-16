(*
 * Copyright (c) 2009-2010 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Camlp4.PreCast
open Syntax

open Dyntype 

let json_of n = "json_of_" ^ n
let of_json n = n ^ "_of_json"

let patt_list_of_list _loc patts =
  match List.rev patts with
  | []   -> <:patt< [] >>
  | h::t -> List.fold_left (fun accu x -> <:patt< [ $x$ :: $accu$ ] >>) <:patt< [ $h$ ] >> t

let patt_tuple_of_list _loc = function
  | []   -> <:patt< >>
  | [x]  -> x
  | h::t -> Ast.PaTup (_loc, List.fold_left (fun accu n -> <:patt< $accu$, $n$ >>) h t)

let expr_list_of_list _loc exprs =
  match List.rev exprs with
  | []   -> <:expr< [] >>
  | h::t -> List.fold_left (fun accu x -> <:expr< [ $x$ :: $accu$ ] >>) <:expr< [ $h$ ] >> t

let expr_list_of_opt_list _loc exprs =

  let rec aux accu = function
    | `Option (eid, pid), x ->
      <:expr< let tl_object_ = $accu$ in match $eid$ with [
        None -> tl_object_
      | Some $pid$ -> [ $x$ :: tl_object_ ] ] >>
    | `Regular, x -> <:expr< [ $x$ :: $accu$ ] >> in

  match List.rev exprs with
  | [] -> <:expr< [] >>
  | (`Option (eid, pid), h) ::t ->
    List.fold_left aux
      <:expr< match $eid$ with [
        None       -> []
      | Some $pid$ -> $h$ ] >>
      t
  | (`Regular, h) ::t -> List.fold_left aux <:expr< [ $h$ ] >> t

let expr_tuple_of_list _loc = function
  | []   -> <:expr< >>
  | [x]  -> x
  | h::t -> Ast.ExTup (_loc, List.fold_left (fun accu n -> <:expr< $accu$, $n$ >>) h t)

let c = ref 0

let new_id _loc _ =
  incr c;
  let v = "var" ^ string_of_int !c in
  <:patt< $lid:v$ >>, <:expr< $lid:v$ >>
;;

(* Conversion ML value -> Json.t value *)
module Json_of = struct
  
  let gen (_loc, n, t_exp) =
    let t = match t_exp with Ext (_,t) | Rec (_,t) -> t | _ -> assert false in
    let rec aux id = function
    | Unit     -> <:expr< Json.Null >>
    | Bool     -> <:expr< Json.Bool $id$ >>
    | Float    -> <:expr< Json.Float $id$ >>
    | Char     -> <:expr< Json.Int (Int64.of_int (Char.code $id$)) >>
    | String   -> <:expr< Json.String $id$ >>

    | Int (Some i) when i + 1 = Sys.word_size ->
      <:expr< Json.Int (Int64.of_int $id$) >>
      
    | Int (Some i) when i <= 32 ->
      <:expr< Json.Int (Int64.of_int32 $id$) >>

    | Int (Some i) when i <= 64 ->
      <:expr< Json.Int $id$ >>

    | Int _ ->
      <:expr< Json.String (Bigint.to_string $id$) >>

    | List (Tuple [String; t ]) -> (* XXX: deal with `type a = string type t = (a * int) list` *)
      let pid, eid = new_id _loc () in
      <:expr< Json.Object (List.map (fun (s, $pid$) -> (s, $aux eid t$)) t) >>
                               
    | List t   ->
      let pid, eid = new_id _loc () in
      <:expr< Json.Array (List.map (fun $pid$ -> $aux eid t$) $id$) >>

    | Array (Tuple [String; t ]) -> (* XXX: deal with `type a = string type t = (a * int) array` *)
      let pid, eid = new_id _loc () in
      <:expr< Json.Object (Array.to_list (Array.map (fun (s, $pid$) -> (s, $aux eid t$)) $id$)) >>
                               
    | Array t   ->
      let pid, eid = new_id _loc () in
      <:expr< Json.Array (Array.to_list (Array.map (fun $pid$ -> $aux eid t$) $id$)) >>

    | Tuple t  ->
      let ids = List.map (new_id _loc) t in
      let patts,exprs = List.split ids in
      let exprs = List.map2 aux exprs t in
      <:expr<
        let $patt_tuple_of_list _loc patts$ = $id$ in
         Json.Array $expr_list_of_list _loc exprs$
        >>

    | Dict (k,d) ->
      let pid,eid = new_id _loc () in
      let new_id n = match k with
        | `R -> <:expr< $id$.$lid:n$ >>
        | `O -> <:expr< $id$#$lid:n$ >> in
      let exprs =
        List.map (function
          | (n,_,Option t) -> (`Option (new_id n, pid), <:expr< ($`str:n$, $aux eid t$) >>)
          | (n,_,t)        -> (`Regular, <:expr< ($`str:n$, $aux (new_id n) t$) >>))
          d in
      let expr = expr_list_of_opt_list _loc exprs in
      <:expr< Json.Object $expr$ >>

    | Sum (k, s) ->
      let mc (n, args) =
        let ids = List.map (new_id _loc) args in
        let patts, exprs = List.split ids in
        let exprs = match args with
          | [] -> <:expr< Json.String $str:n$ >>
          | _  ->
            let largs = <:expr< Json.String $str:n$ >> :: List.map2 aux exprs args in
            <:expr< Json.Array $expr_list_of_list _loc largs$ >> in
        let patt = match k, args with
          | `N, [] -> <:patt< $uid:n$ >>
          | `P, [] -> <:patt< `$uid:n$ >>
          | `N, _  -> List.fold_left (fun accu patt -> <:patt< $accu$ $patt$ >>) <:patt< $uid:n$ >> patts
          | `P, _  -> List.fold_left (fun accu patt -> <:patt< $accu$ $patt$ >>) <:patt< `$uid:n$ >> patts in
        <:match_case< $patt$ -> $exprs$ >> in
      <:expr< match $id$ with [ $list:List.map mc s$ ] >>

    | Option o ->
      let pid, eid = new_id _loc () in
      <:expr<
        match $id$ with [
            None       -> Json.Array []
          | Some $pid$ -> Json.Array [$aux eid o$]
        ] >>

    | Arrow _ -> failwith "arrow type is not supported"

    | Ext ("Json.t",_)
    | Var "Json.t"     -> <:expr< $id$ >>

    | Ext (n,_)
    | Rec (n,_)
    | Var n    ->
      (* XXX: This will not work for recursive values *)
      <:expr< $Pa_dyntype.gen_ident _loc json_of n$ $id$ >> in

    let id = <:expr< $lid:n$ >> in
    <:binding<$lid:json_of n$ $lid:n$ : Json.t = $aux id t$>>

end


(* Conversion Json.t value -> ML value *)
module Of_json = struct

  let str_of_id id = match id with <:expr@loc< $lid:s$ >> -> <:expr@loc< $str:s$ >> | _ -> assert false

  let runtime_error_key_not_found _loc name id expected = <:expr<
    do {
      Printf.eprintf
        "Runtime error in '%s_of_json:%s': key '%s' not found in dictionary\\n"
        $str:name$ $str_of_id id$
        $str:expected$;
      raise (Json.Runtime_error ($str:expected$, Json.Null)) }
  >>

  let runtime_error _loc name id expected =
    <:match_case< error -> do {
      Printf.eprintf
        "Runtime error in '%s_of_json:%s': got '%s' when '%s' was expected\\n"
        $str:name$ $str_of_id id$
        (Json.to_string error)
        $str:expected$;
      raise (Json.Runtime_error ($str:expected$, error)) }
    >>

   let gen (_loc, n, t_exp) =
    let t = match t_exp with Ext (_,t) | Rec (_,t) -> t | _ -> assert false in
    let rec aux id = function
      | Unit -> <:expr< match $id$ with [
          Json.Null -> ()
        | $runtime_error _loc n id "Null"$ ] >>

      | Int (Some i) when i + 1 = Sys.word_size ->
        <:expr< match $id$ with [
          Json.Int x    -> Int64.to_int x
        | Json.String s -> int_of_string s
        | $runtime_error _loc n id "Int(int)"$ ] >>

      | Int (Some i) when i <= 32 ->
        <:expr< match $id$ with [
          Json.Int x    -> Int64.to_int32 x
        | Json.String s -> Int32.of_string s
        | $runtime_error _loc n id "Int(int32)"$ ] >>

      | Int (Some i) when i <= 64 ->
        <:expr< match $id$ with [
          Json.Int x    -> x
        | Json.String s -> Int64.of_string s
        | $runtime_error _loc n id "Int(int64)"$ ] >>

      | Int _ ->
        <:expr< match $id$ with [
          Json.String s -> Bigint.of_string s
        | $runtime_error _loc n id "Int(int64)"$ ] >>

      | Float ->
        <:expr< match $id$ with [
          Json.Float x  -> x
        | Json.Int x    -> Int64.to_float x
        | Json.String s -> float_of_string s
        | $runtime_error _loc n id "Float"$ ] >>

      | Char ->
        <:expr< match $id$ with [
          Json.Int x    -> Char.chr (Int64.to_int x)
        | Json.String s -> Char.chr (int_of_string s)
        | $runtime_error _loc n id "Int(char)"$ ] >>

      | String -> <:expr< match $id$ with [
          Json.String x -> x
        | $runtime_error _loc n id "String(string)"$ ] >>

      | Bool   -> <:expr< match $id$ with [
          Json.Bool x -> x
        | $runtime_error _loc n id "Bool"$ ] >>

      | Tuple t ->
        let ids = List.map (new_id _loc) t in
        let patts,exprs = List.split ids in
        let exprs = List.map2 aux exprs t in
        <:expr< match $id$ with [
          Json.Array $patt_list_of_list _loc patts$ -> $expr_tuple_of_list _loc exprs$
        | $runtime_error _loc n id "Array"$ ] >>

      | List (Tuple [String; t]) -> (* XXX: handle the nested string case *)
        let pid, eid = new_id _loc () in
        <:expr< match $id$ with [
          Json.Object d -> List.map (fun (key, $pid$) -> (key, $aux eid t$)) d
        | $runtime_error _loc n id "Object"$ ] >>

      | List t  ->
        let pid, eid = new_id _loc () in
        <:expr< match $id$ with [
          Json.Array d -> List.map (fun $pid$ -> $aux eid t$) d
        | $runtime_error _loc n id "Array"$ ] >>

      | Array (Tuple [String; t]) -> (* XXX: handle the nested array case *)
        let pid, eid = new_id _loc () in
        <:expr< match $id$ with [
          Json.Object d -> Array.of_list (List.map (fun (key, $pid$) -> (key, $aux eid t$)) d)
        | $runtime_error _loc n id "Object"$ ] >>
            
      | Array t ->
        let pid, eid = new_id _loc () in
        <:expr< match $id$ with [
          Json.Array d -> Array.of_list (List.map (fun $pid$ -> $aux eid t$) d)
        | $runtime_error _loc n id "Array"$ ] >>

      | Dict(`R, d) ->
        let pid, eid = new_id _loc () in
        let field (f,_,t) =
          let pid2, eid2 = new_id _loc () in
          match t with
            | Option tt ->
              <:rec_binding< $lid:f$ =
                if List.mem_assoc $`str:f$ $eid$ then
                  let $pid2$ = List.assoc $`str:f$ $eid$ in
                  Some $aux eid2 tt$
                else
                  None >>
            | _ ->
              <:rec_binding< $lid:f$ = 
                if List.mem_assoc $`str:f$ $eid$ then
                  let $pid2$ = List.assoc $`str:f$ $eid$ in $aux eid2 t$
                else
                  $runtime_error_key_not_found _loc f id n$ >> in
        <:expr< match $id$ with [
          Json.Object $pid$ -> { $Ast.rbSem_of_list (List.map field d)$ }
        | $runtime_error _loc n id "Object"$ ] >>

      | Dict(`O, d) ->
        let pid, eid = new_id _loc () in
        let field (f,_,t) =
          let pid2, eid2 = new_id _loc () in
          match t with
            | Option tt ->
              <:class_str_item< method $lid:f$ =
                if List.mem_assoc $`str:f$ $eid$ then
                  let $pid2$ = List.assoc $`str:f$ $eid$ in
                  Some $aux eid2 tt$
                else
                  None >>
            | _ ->
              <:class_str_item< method $lid:f$ = 
                match List.mem_assoc $`str:f$ $eid$ with [
                  True -> let $pid2$ = List.assoc $`str:f$ $eid$ in $aux eid2 t$
                | $runtime_error _loc f id ("Looking for key "^n)$ ] >> in
        <:expr< match $id$ with [
          Json.Object $pid$ -> object $Ast.crSem_of_list (List.map field d)$ end
        | $runtime_error _loc n id "Object"$ ] >>

      | Sum (k, s) ->
        let mc (n, args) =
          let ids = List.map (new_id _loc) args in
          let patts, exprs = List.split ids in
          let exprs = List.map2 aux exprs args in
          let exprs = match k, args with
            | `N, []   -> <:expr< $uid:n$ >>
            | `P, []   -> <:expr< `$uid:n$ >>
            | `N, args -> List.fold_left (fun accu expr -> <:expr< $accu$ $expr$ >>) <:expr< $uid:n$ >> exprs
            | `P, args -> List.fold_left (fun accu expr -> <:expr< $accu$ $expr$ >>) <:expr< `$uid:n$ >> exprs in
          let patt = match args with
            | [] -> <:patt< Json.String $str:n$ >>
            | _  -> <:patt< Json.Array [ Json.String $str:n$ :: $patt_list_of_list _loc patts$ ] >> in
          <:match_case< $patt$ -> $exprs$ >> in
        <:expr< match $id$ with [
          $list:List.map mc s$
        | $runtime_error _loc n id "Enum[String s;...]"$ ] >>

      | Option t ->
        let pid, eid = new_id _loc () in
        <:expr< match $id$ with [
          Json.Array [] -> None
        | Json.Array [ $pid$ ] -> Some $aux eid t$
        | $runtime_error _loc n id "Enum[]/Enum[_]"$ ] >>

	  | Arrow _  -> failwith "arrow type is not yet supported"

	  | Ext ("Json.t",_)
    | Var "Json.t"     -> <:expr< $id$ >>

	  | Ext (n,_)
	  | Rec (n,_)
	  | Var n    ->
      (* XXX: This will not work for recursive values *)
      <:expr< $Pa_dyntype.gen_ident _loc of_json n$ $id$ >> in

    let id = <:expr< $lid:n$ >> in
    <:binding<$lid:of_json n$ $lid:n$ : $lid:n$ = $aux id t$>>

end

let () =
  Pa_type_conv.add_generator "json"
    (fun tds ->
       try
         let _loc = Ast.loc_of_ctyp tds in
         <:str_item<
           value rec $Ast.biAnd_of_list (List.map Json_of.gen (Pa_dyntype.create tds))$;
           value rec $Ast.biAnd_of_list (List.map Of_json.gen (Pa_dyntype.create tds))$;
         >>
       with Not_found ->
         Printf.eprintf "[Internal Error]\n";
         Printexc.print_backtrace stderr;
         exit (-1))
