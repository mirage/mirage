(*
 * This file is part of ocamljs, OCaml to Javascript compiler
 * Copyright (C) 2007-9 Skydeck, Inc
 * Copyright (C) 2010 Jake Donham
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the Free
 * Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
 * MA 02111-1307, USA
 *)

external assign : 'a -> 'a -> unit = "$assign"
(* external call : 'func -> 'arg1 -> ... -> 'return= "$call" *)
external false_ : unit -> bool = "$false"
external fieldref : 'a -> string -> 'b = "$fieldref"
external function_ : 'a -> 'b = "$function" (* XXX better type? *)
external hashref : 'a -> 'b -> 'c = "$hashref"
(* external new_ : = 'arg1 -> ... -> 'class "$new" "class" *)
external null : unit -> 'a = "$null"
external obj : (string * 'a) list -> 'b = "$obj"
external this : unit -> 'a = "$this"
external throw : 'a -> 'b = "$throw"
external true_ : unit -> bool = "$true"
external var : string -> 'a = "$var"
external (==) : 'a -> 'a -> bool = "%eq"
external (=) : 'a -> 'a -> bool = "%equal"

external caml_callback : ('a -> 'b) -> 'a -> 'b = "caml_callback"
external caml_callback2 : ('a1 -> 'a2 -> 'b) -> 'a1 -> 'a2 -> 'b = "caml_callback2"
external caml_callback3 : ('a1 -> 'a2 -> 'a3 -> 'b) -> 'a1 -> 'a2 -> 'a3 -> 'b = "caml_callback3"
external caml_callback4 : ('a1 -> 'a2 -> 'a3 -> 'a4 -> 'b) -> 'a1 -> 'a2 -> 'a3 -> 'a4 -> 'b = "caml_callback4"
external caml_callback5 : ('a1 -> 'a2 -> 'a3 -> 'a4 -> 'a5 -> 'b) -> 'a1 -> 'a2 -> 'a3 -> 'a4 -> 'a5 -> 'b = "caml_callback5"

(* XXX do these belong here? *)
let option_of_nullable x =
  if x == null()
  then None
  else Some x

let nullable_of_option x =
  match x with
    | None -> null()
    | Some x -> x

let is_null a = a = null ()

(* for backward compatibility *)
type 'a jsfun = 'a
external jsfun : 'a -> 'a = "%identity"
external jsfun2 : 'a -> 'a = "%identity"
external jsfun3 : 'a -> 'a = "%identity"
external jsfun4 : 'a -> 'a = "%identity"
external jsfun5 : 'a -> 'a = "%identity"

module Inline =
struct
  module Jslib_ast =
  struct
    type loc = unit
(*    INCLUDE "../../jslib/jslib_ast.incl" *)
type unop =
    | Jdelete
    | Jvoid
    | Jtypeof
    | Jadd2_pre
    | Jsub2_pre
    | Jadd_pre
    | Jsub_pre
    | Jtilde
    | Jnot
    | Jadd2_post
    | Jsub2_post

and binop =
    | Jhashref
    | Jmul
    | Jdiv
    | Jmod
    | Jadd
    | Jsub
    | Jlt
    | Jgt
    | Jleq
    | Jgeq
    | Jlsr
    | Jlsl
    | Jasr
    | Jeq
    | Jneq
    | Jinstanceof
    | Jseq
    | Jsneq
    | Jland
    | Jlor
    | Jand
    | Jxor
    | Jor
    | Jcomma
    | Jassign
    | Jmul_assign
    | Jdiv_assign
    | Jmod_assign
    | Jadd_assign
    | Jsub_assign
    | Jlsl_assign
    | Jlsr_assign
    | Jasr_assign
    | Jand_assign
    | Jxor_assign
    | Jor_assign

and exp =
    | Jthis of     loc
    | Jvar of      loc * string
    | Jarray of    loc * exp
    | Jobject of   loc * (exp * exp) list
    | Jstring of   loc * string * bool (* true if double-quoted *)
    | Jnum of      loc * string
    | Jnull of     loc
    | Jbool of     loc * bool
    | Jregexp of   loc * string * string
    | Jfun of      loc * string option * string list * stmt
    | Jfieldref of loc * exp * string
    | Junop of     loc * unop * exp
    | Jbinop of    loc * binop * exp * exp
    | Jite of      loc * exp * exp * exp
    | Jcall of     loc * exp * exp
    | Jnew of      loc * exp * exp option
    | Jexp_nil of  loc
    | Jexp_cons of loc * exp * exp
    | Jexp_Ant of  loc * string

and stmt =
    | Jvars of     loc * (string * exp option) list
    | Jfuns of     loc * string * string list * stmt
    | Jreturn of   loc * exp option
    | Jcontinue of loc * string option
    | Jbreak of    loc * string option
    | Jswitch of   loc * exp * (exp * stmt) list * stmt
    | Jites of     loc * exp * stmt * stmt option
    | Jthrow of    loc * exp
    | Jexps of     loc * exp
    | Jtrycatch of loc * stmt * (string * stmt) option * stmt
    | Jfor of      loc * (string * exp option) list * exp option * exp option * exp option * stmt
    | Jdowhile of  loc * stmt * exp
    | Jwhile of    loc * exp * stmt
    | Jblock of    loc * stmt
    | Jwith of     loc * exp * stmt
    | Jlabel of    loc * string * stmt
    | Jstmt_nil of loc
    | Jstmt_cons of loc * stmt * stmt
    | Jstmt_Ant of loc * string

  end

  external inline_exp : Jslib_ast.exp -> 'a = "$inline_exp"
  external inline_stmt : Jslib_ast.stmt -> unit = "$inline_stmt"
  external inline_rstmt : Jslib_ast.stmt -> 'a = "$inline_rstmt"
  external inline_antiexp : 'a -> Jslib_ast.exp = "$inline_antiexp"

  let _loc = ()
end
