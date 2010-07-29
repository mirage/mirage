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
 * $Id: mpl_syntaxtree.ml,v 1.17 2005/12/05 00:46:06 avsm Exp $
 *)
 
open Mpl_utils

module L = Mpl_location

type id = string

type expr =
    | And of (expr * expr)
    | Or of (expr * expr)
    | Identifier of id
    | Not of expr
    | True
    | False
    | Greater of (expr * expr)
    | Less of (expr * expr)
    | Greater_or_equal of (expr * expr)
    | Less_or_equal of (expr * expr)
    | Equals of (expr * expr)
    | Plus of (expr * expr)
    | Minus of (expr * expr)
    | Multiply of (expr * expr)
    | Divide of (expr * expr)
    | Int_constant of int
    | String_constant of string
    | Range of (expr * expr)
    | Function_call of (id * string option)
and exprs = expr list

type vlist = (expr * string) list
type attr =
    |Align of expr
    |Min of expr
    |Max of expr
    |Const of expr
    |Variant of (vlist * expr option)
    |Value of expr
	 |Default of expr
and attrs = attr list

type packet_var =
    |P_bool of string
    |P_int of string

type statement =
    | Packet of (id * id * (id list))
    (* Variable name * type in string * size expression * attrs *)
    | Variable of (id * id * expr option * attrs)
    (* classify (variable) (pattern * name * guard * statements) *)
    | Classify of (id * (expr * expr * expr option * statements) list)
    | Array of (id * expr * statements)
    | Unit
and statements = (Mpl_location.t * statement) list

type packet = {
    name: string;
    args: packet_var list;
    body: statements;
    loc: L.t;
}

type packets = {
	 pdefs: packet list;  (* packets *)
	 tdefs: (string, (L.t * string)) Hashtbl.t; (* typedefs *)
	 sdefs: (string, statements) Hashtbl.t; (* structs *)
}

let packet_var_of_string nm = function
    |"bool"|"boolean" -> Some (P_bool nm)
    |"int"|"integer" -> Some (P_int nm)
    |_ -> None
    
let attr_of_string e = function
    |"min" -> Some (Min e)
    |"max" -> Some (Max e)
    |"align" -> Some (Align e)
    |"const" -> Some (Const e)
    |"value" -> Some (Value e)
    |"default" -> Some (Default e)
    |_ -> None

exception Syntax_error of Mpl_location.t

open Printf

(* Convert expression to a string *)
let rec string_of_expr = function
    | And (a,b) -> sprintf "(%s && %s)" (string_of_expr a) (string_of_expr b)
    | Or (a,b) -> sprintf "(%s || %s)" (string_of_expr a) (string_of_expr b)
    | Identifier i -> i
    | Not e -> sprintf "(!%s)" (string_of_expr e)
    | True -> "true"
    | False -> "false"
    | Greater (a,b) -> sprintf "(%s > %s)" (string_of_expr a) (string_of_expr b)
    | Less (a,b) -> sprintf "(%s < %s)"  (string_of_expr a) (string_of_expr b)
    | Greater_or_equal (a,b) -> sprintf "(%s >= %s)"  (string_of_expr a) (string_of_expr b)
    | Less_or_equal (a,b) -> sprintf "(%s <= %s)"  (string_of_expr a) (string_of_expr b)
    | Equals (a,b) -> sprintf "(%s == %s)"  (string_of_expr a) (string_of_expr b)
    | Plus (a,b) -> sprintf "(%s + %s)" (string_of_expr a) (string_of_expr b)
    | Minus (a,b) -> sprintf "(%s - %s)" (string_of_expr a) (string_of_expr b)
    | Multiply (a,b) -> sprintf "(%s * %s)" (string_of_expr a) (string_of_expr b)
    | Divide (a,b) -> sprintf "(%s / %s)" (string_of_expr a) (string_of_expr b)
    | Int_constant a -> sprintf "%d" a
    | String_constant a -> sprintf "\"%s\"" a
    | Range (a,b) -> sprintf "(%s .. %s)" (string_of_expr a) (string_of_expr b)
    | Function_call (i,a) ->
        let x = match a with |None -> "" |Some b -> b in
        sprintf "%s(%s)" i x

let string_of_attr = function
    |Align e -> sprintf "align=(%s)" (string_of_expr e)
    |Min e -> sprintf "min=(%s)" (string_of_expr e)
    |Max e -> sprintf "max=(%s)" (string_of_expr e)    
    |Value e -> sprintf "value=(%s)" (string_of_expr e)
    |Const e -> sprintf "const=(%s)" (string_of_expr e)
	 |Default e -> sprintf "default=(%s)" (string_of_expr e)
    |Variant (x,def) -> sprintf "variant={%s}" (String.concat ", "
        (List.map (fun (i,t) -> sprintf "%s->%s" (string_of_expr i) t) x))

let string_of_packet_var = function
    |P_bool x -> sprintf "bool %s" x
    |P_int x -> sprintf "int %s" x
