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

(* Fork of http://xenbits.xen.org/xapi/xen-api-libs.hg?file/7a17b2ab5cfc/rpc-light/rpc.ml *)

open Printf

type t =
	| Unit
	| Int of int64
	| Bool of bool
	| Float of float
	| String of string
	| Enum of t list (* all the t of the list should be of same type *)
	| Tuple of t list
	| Dict of (string * t) list
	| Sum of string * t list
	| Null
	| Value of t
	| Arrow of string
	| Rec of (string * int64) * t
	| Var of (string * int64)
	| Ext of (string * int64) * t

(* If there are still some Var v, then the type is recursive for the type v *)
let free_vars t =
	let rec aux accu = function
	| Rec (n,t)  -> aux (List.filter (fun m -> n <> m) accu) t
	| Var n when List.mem n accu -> accu
	| Var n      -> n :: accu
	| Value t     -> aux accu t
	| Enum tl
	| Sum (_,tl)
	| Tuple tl   -> List.fold_left aux accu tl
	| Dict tl    -> List.fold_left (fun accu (_,t) -> aux accu t) accu tl
	| Int _ | Bool _ | Float _ | String _ | Null | Arrow _ | Unit
                     -> accu
	| Ext (_,t)  -> aux accu t in
	aux [] t

let map_strings sep fn l = String.concat sep (List.map fn l)

let equal x y =
	let rec aux ids x y = match x, y with
	| Unit        , Unit        -> true
	| Int i       , Int j       -> i=j
	| Bool i      , Bool j      -> i=j
	| Float i     , Float j     -> i=j
	| String i    , String j    -> i=j
	| Enum i      , Enum j
	| Tuple i     , Tuple j     -> List.length i = List.length j && List.for_all (fun x -> x) (List.map2 (aux ids) i j)
	| Dict i      , Dict j      ->
		let fn a b = List.for_all (fun (n,i) -> List.exists (fun (m,j) -> n=m && (aux ids) i j) a) b in
		fn i j
	| Sum (n,i)   , Sum (m,j)   -> n=m && List.length i = List.length j && List.for_all (fun x -> x) (List.map2 (aux ids) i j)
	| Null        , Null        -> true
	| Value i     , Value j     -> aux ids i j
	| Var (n,i)   , Var (m,j)   -> n=m && i = List.assoc (n, j) ids
	| Rec((n,i),v), Rec((m,j),w)-> n=m && aux ( ((n,j), i) :: ids ) v w
	| Arrow _     , Arrow _     -> true
	| Ext((n,i),v), Ext((m,j),w)-> n=m && aux ids v w
	| _                         -> false in
	aux [] x y

let rec to_string t = match t with
	| Unit       -> "U"                                                           
	| Null       -> "N"
	| Value t    -> sprintf "?%s" (to_string t)
	| Int i      -> sprintf "I(%Li)" i
	| Bool b     -> sprintf "B(%b)" b
	| Float f    -> sprintf "F(%f)" f
	| String s   -> sprintf "S(%s)" s
	| Enum ts    -> sprintf "[%s]" (map_strings ";" to_string ts)
	| Tuple ts   -> sprintf "(%s)" (map_strings ";" to_string ts)
	| Dict ts    -> sprintf "{%s}" (map_strings ";" (fun (s,t) -> sprintf "%s:%s" s (to_string t)) ts)
	| Sum (n,ts) -> sprintf "<%s>" (let r = map_strings ";" to_string ts in if r = "" then n else n^";"^r)
	| Rec ((n,i),t) -> sprintf "R@%s@%Ld@%s" n i (to_string t)
	| Var (n,i)  -> sprintf "@%s@%Ld" n i
	| Arrow f    -> sprintf "#%s" f
	| Ext ((n,i),t) -> sprintf "E/%s/%Ld/%s" n i (to_string t)

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

let rec of_string s =
	match s.[0] with
	| 'U' -> Unit
	| 'N' -> Null
	| 'I' -> Int (Int64.of_string (String.sub s 2 (String.length s - 3)))
	| 'B' -> Bool (bool_of_string (String.sub s 2 (String.length s - 3)))
	| 'F' -> Float (float_of_string (String.sub s 2 (String.length s - 3)))
	| 'S' -> String (String.sub s 2 (String.length s - 3))
	| '[' ->
		let s = String.sub s 1 (String.length s - 2) in
		let ss = split_par ';' s in
		Enum (List.map of_string ss)
	| '(' ->
		let s = String.sub s 1 (String.length s - 2) in
		let ss = split_par ';' s in
		Tuple (List.map of_string ss)
	| '{' ->
		let s = String.sub s 1 (String.length s - 2) in
		let ss = split_par ';' s in
		let ss = List.map (split_par ~limit:2 ':') ss in
		Dict (List.map (fun x -> match x with [s;t] -> (s, of_string t) | _ -> parse_error s) ss)
	| '<' ->
		let s = String.sub s 1 (String.length s - 2) in
		let ss = split_par ';' s in
		Sum (List.hd ss,  (List.map of_string (List.tl ss)))
	| 'R' ->
		begin match split_par ~limit:4 '@' s with
		| [ "R"; var; i; t ] -> Rec ((var, Int64.of_string i), of_string t)
		| _ -> parse_error s
		end
	| '@' -> begin match split_par ~limit:3 '@' s with
		| [ _; var; i ] -> Var (var, Int64.of_string i)
		| _ -> parse_error s
	  end
	| 'E' -> begin match split_par ~limit:4 '/' s with
		| [ "E"; var; id; t ] -> Ext ((var, Int64.of_string id), of_string t)
		| _ -> parse_error s
	  end
	| '#' -> Arrow (String.sub s 1 (String.length s - 1))
	| '?' -> Value (of_string (String.sub s 1 (String.length s - 1)))
	| _   -> parse_error s

