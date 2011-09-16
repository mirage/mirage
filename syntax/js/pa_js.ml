(* Js_of_ocaml library
 * http://www.ocsigen.org/js_of_ocaml/
 * Copyright (C) 2010 Jérôme Vouillon
 * Laboratoire PPS - CNRS Université Paris Diderot
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)

let rnd = Random.State.make [|0x513511d4|]
let random_var () =
  Format.sprintf "a%08Lx" (Random.State.int64 rnd 0x100000000L)

open Camlp4

module Id : Sig.Id = struct
  let name = "Javascript"
  let version = "1.0"
end

module Make (Syntax : Sig.Camlp4Syntax) = struct
  open Sig
  include Syntax

  let rec filter stream =
    match stream with parser
      [< '(KEYWORD "#", loc); rest >] ->
        begin match rest with parser
          [< '(KEYWORD "#", loc') >] ->
             [< '(KEYWORD "##", Loc.merge loc loc'); filter rest >]
        | [< >] ->
             [< '(KEYWORD "#", loc); filter rest >]
        end
    | [< 'other; rest >] -> [< 'other; filter rest >]

  let _ =
    Token.Filter.define_filter (Gram.get_filter ())
      (fun old_filter stream -> old_filter (filter stream))

  let rec parse_comma_list e =
    match e with
      <:expr< $e1$, $e2$ >> -> e1 :: parse_comma_list e2
    | _                    -> [e]

  let rec to_sem_expr _loc l =
    match l with
      []        -> assert false
    | [e]       -> e
    | e1 :: rem -> <:expr< $e1$; $to_sem_expr _loc rem$ >>

  let make_array _loc l =
    match l with
      [] -> <:expr< [| |] >>
    | _  -> <:expr< [| $to_sem_expr _loc l$ |] >>

  let with_type e t =
    let _loc = Ast.loc_of_expr e in <:expr< ($e$ : $t$) >>

  let unescape lab =
    assert (lab <> "");
    let lab =
      if lab.[0] = '_' then String.sub lab 1 (String.length lab - 1) else lab
    in
    try
      let i = String.rindex lab '_' in
      if i = 0 then raise Not_found;
      String.sub lab 0 i
    with Not_found ->
      lab

  let fresh_type _loc = <:ctyp< '$random_var ()$ >>

  let access_object e m m_loc m_typ f =
    let _loc = Ast.loc_of_expr e in
    let x = random_var () in
    let obj_type = fresh_type _loc in
    let obj = <:expr< ($e$ : Js.t (< .. > as $obj_type$)) >> in
    let constr =
      let y = random_var () in
      let body =
        let o = <:expr< $lid:y$ >> in
        let _loc = m_loc in <:expr< ($o$#$m$ : $m_typ$) >>
      in
      <:expr< fun ($lid:y$ : $obj_type$) -> $body$ >>
    in
    <:expr< let $lid:x$ = $obj$ in
            let _ = $constr$ in
            $f x$ >>

  let method_call _loc obj lab lab_loc args =
    let args = List.map (fun e -> (e, fresh_type _loc)) args in
    let ret_type = fresh_type _loc in
    let method_type =
      List.fold_right
        (fun (_, arg_ty) rem_ty -> <:ctyp< $arg_ty$ -> $rem_ty$ >>)
        args <:ctyp< Js.meth $ret_type$ >>
    in
    access_object obj lab lab_loc method_type (fun x ->
    let args =
      List.map (fun (e, t) -> <:expr< Js.Unsafe.inject $with_type e t$ >>) args
    in
    let args = make_array _loc args in
    <:expr<
       (Js.Unsafe.meth_call $lid:x$ $str:unescape lab$ $args$ : $ret_type$)
    >>)

  let new_object _loc constructor args =
    let args = List.map (fun e -> (e, fresh_type _loc)) args in
    let obj_type = <:ctyp< Js.t $fresh_type _loc$ >> in
    let constr_fun_type =
      List.fold_right
        (fun (_, arg_ty) rem_ty -> <:ctyp< $arg_ty$ -> $rem_ty$ >>)
        args obj_type
    in
    let args =
      List.map (fun (e, t) -> <:expr< Js.Unsafe.inject $with_type e t$ >>) args
    in
    let args = make_array _loc args in
    let x = random_var () in
    let constr =
      with_type constructor <:ctyp< Js.constr $constr_fun_type$ >> in
    with_type
      <:expr< let $lid:x$ = $constr$ in
              Js.Unsafe.new_obj $lid:x$ $args$ >>
      <:ctyp< $obj_type$ >>

  let jsmeth = Gram.Entry.mk "jsmeth"

  EXTEND Gram
    jsmeth: [["##"; lab = label -> (_loc, lab) ]];
    expr: BEFORE "."
    ["##" RIGHTA
     [ e = SELF; (lab_loc, lab) = jsmeth ->
         let prop_type = fresh_type _loc in
         let meth_type = <:ctyp< Js.gen_prop <get:$prop_type$; ..> >> in
         access_object e lab lab_loc meth_type (fun x ->
         <:expr< (Js.Unsafe.get $lid:x$ $str:unescape lab$ : $prop_type$) >>)
     | e1 = SELF; (lab_loc, lab) = jsmeth; "<-"; e2 = expr LEVEL "top" ->
         let prop_type = fresh_type _loc in
         let meth_type = <:ctyp< Js.gen_prop <set:$prop_type$->unit; ..> >> in
         access_object e1 lab lab_loc meth_type (fun x ->
         <:expr<
           Js.Unsafe.set $lid:x$ $str:unescape lab$ ($e2$ : $prop_type$)
         >>)
     | e = SELF; (lab_loc, lab) = jsmeth; "("; ")" ->
         method_call _loc e lab lab_loc []
     | e = SELF; (lab_loc, lab) = jsmeth; "("; l = comma_expr; ")" ->
         method_call _loc e lab lab_loc (parse_comma_list l)
     ]];
    expr: LEVEL "simple"
    [[ "jsnew"; e = expr LEVEL "label"; "("; ")" ->
         new_object _loc e []
     | "jsnew"; e = expr LEVEL "label"; "("; l = comma_expr; ")" ->
         new_object _loc e (parse_comma_list l) ]];
    END

(*XXX n-ary methods

how to express optional fields?  if they are there, they must have
some type, but  they do not have to be there

use variant types instead of object types?
   in a negative position...  (but then we have to negate again...)

    { foo: "bar", baz : 7 } : [`foo of string field | `baz of int field] obj

    let f (x : t) = (x : [< `foo of string field | `baz of int field| `x of string field] obj)


XXXX
module WEIRDMODULENAME = struct type 'a o = 'a Js.t val unsafe_get = Js.Unsafe.get ... end
(let module M = WEIRDMODULENAME in (M.unsafe_get : <x : 'a M.meth> -> 'a))

XXXX be more careful with error messages:
  put coercions against arguments or whole expression
*)

end

module M = Register.OCamlSyntaxExtension(Id)(Make)
