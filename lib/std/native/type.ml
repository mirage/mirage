open Pervasives
(*
 * Copyright (c) 2009-2010 Thomas Gazagnaire <thomas@gazagnaire.com>
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

open Printf

(* mutable or immutable *)
type t =
  | Unit | Bool | Float | Char | String
  | Int of int option
  | Enum of t
  | Tuple of t list
  | Dict of (string * [`RW|`RO] * t) list
  | Sum of (string * t list) list
  | Option of t
  | Rec of string * t
  | Var of string
  | Arrow of t * t
  | Ext of string * t

(* Check whether a struct is mutable *)
let is_mutable t =
  let rec aux = function
    | Unit | Int _ | Bool | Float | Char | String -> false
    | Enum t    -> aux t
    | Tuple tl  -> List.exists aux tl
    | Dict tl   -> List.exists (fun (_,m,t) -> m = `RW || aux t) tl
    | Sum tl    -> List.exists (fun (_,tl) -> List.exists aux tl) tl
    | Option t  -> aux t
    | Rec (n,t) -> aux t
    | Var n     -> false
    | Arrow _   -> false
    | Ext (n,t) -> aux t in
  aux t

(* If there are still some `Var v, then the type is recursive for the type v *)
let free_vars t =
  let rec aux accu = function
    | Rec (n,t) -> List.filter (fun m -> n <> m) (aux accu t)
    | Var n when List.mem n accu
                -> accu
    | Var n     -> n :: accu
    | Enum t
    | Option t  -> aux accu t
    | Tuple ts  -> List.fold_left aux accu ts
    | Dict ts   -> List.fold_left (fun accu (_,_,t) -> aux accu t) accu ts
    | Sum ts    -> List.fold_left (fun accu (_,t) -> List.fold_left aux accu t) accu ts
    | Unit | Int _ | Bool | Float | Char | String
                 -> accu
    | Arrow(t,s) -> aux (aux accu t) s
    | Ext (n,t)  -> aux accu t in
  aux [] t

(* Get all the type variables defined inside a type *)
let foreigns t =
	let rec aux accu = function
    | Ext (n,t)
    | Rec (n,t) when List.mem n accu
                -> aux accu t
    | Ext (n,t)
    | Rec (n,t) -> aux (n::accu) t
    | Var n when List.mem n accu
                -> accu
    | Var n     -> n :: accu
    | Enum t
    | Option t  -> aux accu t
    | Tuple ts  -> List.fold_left aux accu ts
    | Dict ts   -> List.fold_left (fun accu (_,_,t) -> aux accu t) accu ts
    | Sum ts    -> List.fold_left (fun accu (_,t) -> List.fold_left aux accu t) accu ts
    | Unit | Int _ | Bool | Float | Char | String
                 -> accu
    | Arrow(t,s) -> aux (aux accu t) s in
  aux [] t

(* Replace the Vars  by their type contained in env, and update the Ext/Rec stuff *)
let unroll env t =
  let rec aux name = function
    | Rec (m, _) | Ext (m, _) when m = name
                 -> Var name
    | Rec (m, s) 
    | Ext (m, s) -> let ss = aux name s in if List.mem m (free_vars ss) then Rec (m, ss) else Ext (m, ss)
    | Var n when List.mem_assoc n env
                 -> aux name (List.assoc n env)
    | Var _ | Unit | Int _ | Bool | Float | Char | String as t
                 -> t
    | Enum t     -> Enum (aux name t)
    | Tuple tl   -> Tuple (List.map (aux name) tl)
    | Dict tl    -> Dict (List.map (fun (n, m, t) -> (n, m, aux name t)) tl)
    | Sum tl     -> Sum (List.map (fun (n, tl) -> (n, List.map (aux name) tl)) tl)
    | Option t   -> Option (aux name t)
	| Arrow(s,t) -> Arrow (aux name s, aux name t) in
  match t with
  | Rec (n, s) | Ext (n, s) -> let ss = aux n s in if List.mem n (free_vars ss) then Rec (n, ss) else Ext (n, ss)
  | _                       -> t

let map_strings sep fn l = String.concat sep (List.map fn l)

let rec to_string t = match t with                                                                    
  | Unit       -> "U"
  | Int x      -> "I" ^ (match x with None -> "" | Some n -> sprintf "%02d" n)
  | Bool       -> "B"
  | Float      -> "F"
  | Char       -> "C"
  | String     -> "S"
  | Enum t     -> sprintf "[%s]" (to_string t)
  | Tuple ts   -> sprintf "(%s)" (map_strings "*" to_string ts)
  | Dict ts    -> sprintf "{%s}" (map_strings "*" (fun (s,m,t) -> sprintf "%s:%s:%s" s (if m = `RO then "I" else "M") (to_string t)) ts)
  | Sum ts     -> sprintf "<%s>" (map_strings "*" (fun (s,t) -> sprintf "%s:(%s)" s (map_strings "*" to_string t)) ts)
  | Option t   -> sprintf "?%s" (to_string t)
  | Rec (n,t)  -> sprintf "R@%s@%s" n (to_string t)
  | Var n      -> sprintf "@%s" n
  | Arrow(a,b) -> sprintf "#(%s)#(%s)" (to_string a) (to_string b)
  | Ext (n,t)  -> sprintf "E/%s/%s" n (to_string t)

(* Is [t1] a subtype of [t2] ?                                                *)
(* Our subtype relation is the following:                                     *)
(*  if value of type t2 are stored in the database, then a value of a type t1 *)
(*  can be naturally build from that stored value.                            *)
let last_type_error : (t * t) option ref = ref None
let string_of_last_type_error () =
  match !last_type_error with
  | None -> ""
  | Some (t,s) ->
    Printf.sprintf "==type conflict==\ntype: %s\nis not a subtype of\ntype: %s\n=================\n"
      (to_string t) (to_string s)

let is_subtype_of (t1:t) (t2:t) =
  let table = Hashtbl.create 128 in
  let found_error = ref false in
  let rec (<:) t s =
    if Hashtbl.mem table (t,s) then
      Hashtbl.find table (t,s)
    else begin
      let result = match (t,s) with
      | Rec (n,tt) , Rec (m,ss) -> n = m && tt <: ss
      | Ext (n,tt) , Ext (m,ss) -> n = m && tt <: ss
      | Var v      , Var w      -> v = w
      | Enum tt    , Enum ss    -> tt <: ss
      | Option tt  , Option ss  -> tt <: ss
      | Option tt  , _          -> tt <: s
      | Tuple ts   , Tuple ss   -> List.for_all2 (<:) ts ss
      | Dict ts    , Dict ss    -> List.for_all (fun (x1,_,y1) -> List.exists (fun (x2,m,y2) -> m=m && x1=x2 && y1 <: y2) ss) ts
      | Sum ts     , Sum ss     ->
        List.for_all (fun (x2,y2) -> List.exists (fun (x1,y1) -> x1=x2 && List.for_all2 (<:) y1 y2) ts) ss
        && List.for_all (fun (x1,_) -> List.exists (fun (x2,_) -> x1=x2) ss) ts (* TODO: this can be improved later *)
      | Unit, Unit
      | Int None, Int _ -> true
      | Int (Some x), Int None -> false
      | Int (Some x), Int (Some y) -> y <= x
      | Int (Some x), Char -> x >= 8
      | Bool, Bool
      | Float, Float
      | Char, Char
      | String, Char | String, String  
                                -> true
      | _                       -> false in
      Hashtbl.replace table (t,s) result;
      if not result && not !found_error then begin
        last_type_error := Some (t,s);
        found_error := true;
      end;
      result
    end in
  t1 <: t2

let (<:) = is_subtype_of

let index_par c s =
  let res = ref None in
  let par = ref 0 in
  let i = ref 0 in
  let n = String.length s in
  while !res = None && !i < n do
    if s.[!i] = '(' || s.[!i] = '[' || s.[!i] = '{' || s.[!i] = '<' then incr par;
    if s.[!i] = ')' || s.[!i] = ']' || s.[!i] = '}' || s.[!i] = '>' then decr par;
    if !par = 0 && s.[!i] = c then res := Some !i;
    incr i
  done;
  match !res with
  | None -> raise Not_found
  | Some i -> i

let split_par ?limit c s =
  let rec aux n s =
    match limit with
    | Some i when n>=i -> [s]
    | _ ->
      try 
        let i = index_par c s in
        let h = String.sub s 0 i in
        let t =
           try aux (n-1) (String.sub s (i+1) (String.length s - i - 1))
           with _ -> []
        in
        h :: t
      with _ ->
        [s] in
  aux 1 s

exception Parse_error of string
let parse_error s = raise (Parse_error s)

let rec of_string s : t  = match s.[0] with
  | 'U' -> Unit
  | 'I' when String.length s = 1 -> Int None
  | 'I' -> Int (Some (int_of_string (String.sub s 1 (String.length s - 1))))
  | 'B' -> Bool
  | 'F' -> Float
  | 'C' -> Char
  | 'S' -> String
  | '[' ->
    let s = String.sub s 1 (String.length s - 2) in
    Enum (of_string s)
  | '(' ->
    let s = String.sub s 1 (String.length s - 2) in
    let ss = split_par '*' s in
    Tuple (List.map of_string ss)
  | '{' ->
    let s = String.sub s 1 (String.length s - 2) in
    let ss = split_par '*' s in
    let ss = List.map (split_par ~limit:3 ':') ss in
    let ss = List.map (fun x -> match x with 
      | [s;"I";t] -> (s, `RO, of_string t) 
      | [s;"M";t] -> (s, `RW, of_string t) 
      | _ -> parse_error s) ss in
    Dict ss
  | '<' ->
    let s = String.sub s 1 (String.length s - 2) in
    let ss = split_par '*' s in
    let ss = List.map (split_par ~limit:2 ':') ss in
    let ss = List.map (fun x -> match x with
      | [s;"()"] -> (s, [])
      | [s;t] ->
        let t = String.sub t 1 (String.length t - 2) in
        (s, List.map of_string (split_par '*' t))
      | _ -> parse_error s) ss in
    Sum ss
  | '?' -> Option (of_string (String.sub s 1 (String.length s - 1)))
  | 'R' ->
     begin match split_par ~limit:3 '@' s with
     | [ "R"; var; t ] -> Rec (var, of_string t)
     | _ -> parse_error s
     end
  | '@' -> Var (String.sub s 1 (String.length s - 1))
  | '#' ->
    begin match split_par '#' s with
    | ["";s;t] ->
      let ss = String.sub s 1 (String.length s - 2) in
      let tt = String.sub t 1 (String.length t - 2) in
      Arrow (of_string ss, of_string tt)
    | _ -> parse_error s
    end
  | 'E' ->
    begin match split_par '/' s with
    | ["E"; var; t ] -> Ext (var, of_string t)
    | _ -> parse_error s
    end
  | _   -> parse_error s

