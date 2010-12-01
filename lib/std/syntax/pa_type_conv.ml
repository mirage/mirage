(*pp camlp4orf *)

(* File: pa_type_conv.ml

    Copyright (C) 2005-

      Jane Street Holding, LLC
      Author: Markus Mottl
      email: mmottl\@janestreet.com
      WWW: http://www.janestreet.com/ocaml

   This file is derived from file "pa_tywith.ml" of version 0.45 of the
   library "Tywith".

   Tywith is Copyright (C) 2004, 2005 by

      Martin Sandin  <msandin@hotmail.com>

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*)

(* Pa_type_conv: Preprocessing Module for Registering Type Conversions *)

open Printf
open Lexing

open Camlp4
open PreCast
open Ast

(* Utility functions *)

let both fa fb (a, b) = fa a, fb b

let get_loc_err loc msg =
  sprintf "File \"%s\", line %d, characters %d-%d: %s"
    (Loc.file_name loc) (Loc.start_line loc)
    (Loc.start_off loc - Loc.start_bol loc)
    (Loc.stop_off loc - Loc.stop_bol loc)
    msg

(* To be deleted once the OCaml team fixes Mantis issue #4751. *)
let hash_variant str =
  let acc_ref = ref 0 in
  for i = 0 to String.length str - 1 do
    acc_ref := 223 * !acc_ref + Char.code str.[i]
  done;
  if Sys.word_size = 32 then !acc_ref
  else !acc_ref land int_of_string "0x7FFFFFFF"


(* Module/File path management *)

type path =
  | Not_initialized  (* Initial state *)
  | Too_late  (* already in a submodule, too late to initialize *)
  | Path of string * string list  (* Actually initialized *)

(* Reference storing the path to the currently preprocessed module *)
let conv_path_ref = ref Not_initialized

let get_conv_path_el () =
  match !conv_path_ref with
  | Path (e, el) -> e, el
  | _ -> failwith "Pa_type_conv: path not set"

(* Get path to the currently preprocessed module *)
let get_conv_path () = fst (get_conv_path_el ())

(* Set path to the currently preprocessed module *)
let set_conv_path conv_path =
  if !conv_path_ref = Not_initialized || !Sys.interactive then
    conv_path_ref := Path (conv_path, [conv_path])
  else failwith "Pa_type_conv: module name set twice"

let () = if !Sys.interactive then set_conv_path "Toplevel"

let push_conv_path mod_name =
  match !conv_path_ref with
  | Not_initialized -> conv_path_ref := Too_late (* Entered a submodule *)
  | Too_late -> ()
  | Path (str, rev_lst) ->
      conv_path_ref := Path (str ^ "." ^ mod_name, mod_name :: rev_lst)

let pop_conv_path () =
  match !conv_path_ref with
  | Path (_, _ :: rev_lst) ->
      conv_path_ref := Path (String.concat "." (List.rev rev_lst), rev_lst)
  | _ -> ()


(* Generator registration *)


(* Map of "with"-generators for types in structures *)
let generators = Hashtbl.create 0

(* Map of "with"-generators for types in signatures *)
let sig_generators = Hashtbl.create 0

(* Map of "with"-generators for exceptions in structures *)
let exn_generators = Hashtbl.create 0

(* Map of "with"-generators for exceptions in signatures *)
let sig_exn_generators = Hashtbl.create 0

(* Check that there is no argument for generators that do not expect
   arguments *)
let no_arg id e typ arg =
  if arg = None then e typ
  else
    failwith (
      "Pa_type_conv: generator '" ^ id ^ "' does not expect an argument")

(* Parse a list of tokens with the given grammar entry *)
let parse_with entry = function
  | Some tokens ->
      Some (Gram.parse_tokens_after_filter entry (Stream.of_list tokens))
  | None -> None

(* Entry which ignores its input *)
let ignore_tokens = Gram.Entry.of_parser "ignore_tokens" ignore

(* Add new generator, fail if already defined *)
let safe_add_gen gens id entry e =
  if Hashtbl.mem gens id then
    failwith ("Pa_type_conv: generator '" ^ id ^ "' defined multiple times")
  else Hashtbl.add gens id (fun typ arg -> e typ (parse_with entry arg))

(* Register a "with"-generator for types in structures *)
let add_generator_with_arg ?(is_exn = false) id entry e =
  let gens = if is_exn then exn_generators else generators in
  safe_add_gen gens id entry e

let add_generator ?is_exn id e =
  add_generator_with_arg ?is_exn id ignore_tokens (no_arg id e)

(* Removes a "with"-generator for types in structures *)
let rm_generator ?(is_exn = false) id =
  let gens = if is_exn then exn_generators else generators in
  Hashtbl.remove gens id

(* Register a "with"-generator for types in signatures *)
let add_sig_generator_with_arg ?(is_exn = false) id entry e =
  let gens = if is_exn then sig_exn_generators else sig_generators in
  safe_add_gen gens id entry e

let add_sig_generator ?is_exn id e =
  add_sig_generator_with_arg ?is_exn id ignore_tokens (no_arg id e)

(* Removes a "with"-generator for types in signatures *)
let rm_sig_generator ?(is_exn = false) id =
  let gens = if is_exn then sig_exn_generators else sig_generators in
  Hashtbl.remove gens id


(* General purpose code generation module *)

module Gen = struct
  let rec ty_var_list_of_ctyp tp acc =
    match tp with
    | <:ctyp< $tp1$ $tp2$ >> ->
        ty_var_list_of_ctyp tp1 (ty_var_list_of_ctyp tp2 acc)
    | <:ctyp< '$param$ >> -> param :: acc
    | _ -> invalid_arg "ty_var_list_of_ctyp"

  let rec get_rev_id_path tp acc =
    match tp with
    | <:ident< $id1$ . $id2$ >> -> get_rev_id_path id2 (get_rev_id_path id1 acc)
    | <:ident< $lid:id$ >> | <:ident< $uid:id$ >> -> id :: acc
    | _ -> invalid_arg "get_rev_id_path"

  let mk_ident _loc str =
    let first = str.[0] in
    if first >= 'A' && first <= 'Z' then <:ident< $uid:str$ >>
    else <:ident< $lid:str$ >>

  let rec ident_of_rev_path _loc = function
    | [str] -> mk_ident _loc str
    | str :: strs ->
        <:ident< $ident_of_rev_path _loc strs$ . $mk_ident _loc str$ >>
    | _ -> invalid_arg "ident_of_rev_path"

  let rec get_appl_path _loc = function
    | <:ctyp< $id:id$ >> -> id
    | <:ctyp< $tp$ $_$ >> -> get_appl_path _loc tp
    | _ -> failwith "get_appl_path: unknown type"

  let abstract _loc = List.fold_right (fun p e -> <:expr< fun $p$ -> $e$ >>)
  let apply _loc = List.fold_left (fun f arg -> <:expr< $f$ $arg$ >>)

  let idp _loc id = <:patt< $lid:id$ >>
  let ide _loc id = <:expr< $lid:id$ >>

  let switch_tp_def _loc ~alias ~sum ~record ~variants ~mani ~nil tp =
    let rec loop = function
      | <:ctyp< private $tp$ >> -> loop tp
      | <:ctyp< [ $alts$ ] >> -> sum _loc alts
      | <:ctyp< [< $row_fields$ ] >> | <:ctyp< [> $row_fields$ ] >>
      | <:ctyp< [= $row_fields$ ] >> -> variants _loc row_fields
      | <:ctyp< $id:_$ >>
      | <:ctyp< ( $tup:_$ ) >>
      | <:ctyp< $_$ -> $_$ >>
      | <:ctyp< '$_$ >>
      | <:ctyp< $_$ $_$ >> as tp_def -> alias _loc tp_def
      | <:ctyp< { $flds$ } >> -> record _loc flds
      | <:ctyp< $tp1$ == $tp2$ >> -> mani _loc tp1 tp2
      | <:ctyp< >> -> nil _loc
      | _ -> failwith "switch_tp_def: unknown type"
    in
    loop tp

  let rec mk_expr_lst _loc = function
    | [] -> <:expr< [] >>
    | e :: es -> <:expr< [$e$ :: $mk_expr_lst _loc es$] >>

  let rec mk_patt_lst _loc = function
    | [] -> <:patt< [] >>
    | p :: ps -> <:patt< [$p$ :: $mk_patt_lst _loc ps$] >>

  let get_tparam_id = function
    | <:ctyp< '$id$ >> | <:ctyp< +'$id$ >> | <:ctyp< -'$id$ >> -> id
    | _ -> failwith "get_tparam_id: not a type parameter"

  let type_is_recursive _loc type_name tp =
    let rec loop = function
      | <:ctyp< private $tp$>> -> loop tp
      | <:ctyp< $tp1$ $tp2$ >>
      | <:ctyp< $tp1$ * $tp2$ >>
      | <:ctyp< $tp1$; $tp2$ >>
      | <:ctyp< $tp1$ -> $tp2$ >>
      | <:ctyp< $tp1$ == $tp2$ >>
      | <:ctyp< $tp1$ and $tp2$ >>
      | <:ctyp< $tp1$ | $tp2$ >> -> loop tp1 || loop tp2
      | <:ctyp< ( $tup:tp$ ) >> | <:ctyp< { $tp$ } >>
      | <:ctyp< [ $tp$ ] >>
      | <:ctyp< $_$ : $tp$ >>
      | <:ctyp< ~ $_$ : $tp$ >>
      | <:ctyp< mutable $tp$ >>
      | <:ctyp< $_$ of $tp$ >>
      | <:ctyp< [< $tp$ ] >> | <:ctyp< [> $tp$ ] >> | <:ctyp< [= $tp$ ] >>
      | <:ctyp< ! $_$ . $tp$ >> -> loop tp
      | <:ctyp< $lid:id$ >> -> id = type_name
      | <:ctyp< $id:_$ >>
      | <:ctyp< #$id:_$ >>
      | <:ctyp< `$_$ >>
      | <:ctyp< '$_$ >>
      | <:ctyp< >> -> false
      | _ ->
          prerr_endline (
            get_loc_err _loc "type_is_recursive: unknown type construct");
          exit 1
    in
    loop tp

  let drop_variance_annotations _loc =
    (map_ctyp (function
      | <:ctyp< +'$var$ >> | <:ctyp< -'$var$ >> -> <:ctyp< '$var$ >>
      | tp -> tp))#ctyp
end


(* Functions for interpreting derivation types *)

let generate tp (drv_id, drv_arg) =
  try Hashtbl.find generators drv_id tp drv_arg
  with Not_found ->
    failwith (
      "Pa_type_conv: '" ^ drv_id ^ "' is not a supported type generator.")

let gen_derived_defs _loc tp drvs =
  let coll drv der_sis = <:str_item< $der_sis$; $generate tp drv$ >> in
  List.fold_right coll drvs <:str_item< >>

let generate_exn tp (drv_id, drv_arg) =
  try Hashtbl.find exn_generators drv_id tp drv_arg
  with Not_found ->
    failwith (
      "Pa_type_conv: '" ^ drv_id ^ "' is not a supported exception generator.")

let gen_derived_exn_defs _loc tp drvs =
  let coll drv der_sis = <:str_item< $der_sis$; $generate_exn tp drv$ >> in
  List.fold_right coll drvs <:str_item< >>

let sig_generate tp (drv_id, drv_arg) =
  try Hashtbl.find sig_generators drv_id tp drv_arg
  with Not_found ->
    failwith (
      "Pa_type_conv: '" ^ drv_id ^ "' is not a supported signature generator.")

let gen_derived_sigs _loc tp drvs =
  let coll drv der_sis = <:sig_item< $der_sis$; $sig_generate tp drv$ >> in
  List.fold_right coll drvs (SgNil _loc)

let sig_exn_generate tp (drv_id, drv_arg) =
  try Hashtbl.find sig_exn_generators drv_id tp drv_arg
  with Not_found ->
    failwith (
      "Pa_type_conv: '" ^ drv_id ^ "' is not a supported signature generator.")

let gen_derived_exn_sigs _loc tp drvs =
  let coll drv der_sis = <:sig_item< $der_sis$; $sig_exn_generate tp drv$ >> in
  List.fold_right coll drvs (SgNil _loc)


(* Syntax extension *)

open Syntax

let is_prefix ~prefix x =
  let prefix_len = String.length prefix in
  String.length x >= prefix_len && prefix = String.sub x 0 prefix_len

let chop_prefix ~prefix x =
  if is_prefix ~prefix x then
    let prefix_len = String.length prefix in
    Some (String.sub x prefix_len (String.length x - prefix_len))
  else None

let get_default_path _loc =
  try
    let prefix = Sys.getenv "TYPE_CONV_ROOT" in
    match chop_prefix ~prefix (Loc.file_name (Loc.make_absolute _loc)) with
    | Some x -> x ^ "#"
    | None -> Loc.file_name _loc
  with _ -> Loc.file_name _loc

let set_conv_path_if_not_set _loc =
  if !conv_path_ref = Not_initialized || !Sys.interactive then
    let conv_path = get_default_path _loc in
    conv_path_ref := Path (conv_path, [conv_path])

let found_module_name =
  Gram.Entry.of_parser "found_module_name" (fun strm ->
    match Stream.npeek 1 strm with
    | [(UIDENT name, token_info)] ->
        set_conv_path_if_not_set (Gram.token_location token_info);
        push_conv_path name;
        Stream.junk strm;
        name
    | _ -> raise Stream.Failure)

let rec fetch_generator_arg paren_count strm =
  match Stream.next strm with
  | KEYWORD "(", _ -> fetch_generator_arg (paren_count + 1) strm
  | KEYWORD ")", token_info ->
      if paren_count = 1 then [(EOI, token_info)]
      else fetch_generator_arg (paren_count - 1) strm
  | EOI, token_info ->
      Loc.raise (Gram.token_location token_info) (Stream.Error "')' missing")
  | x -> x :: fetch_generator_arg paren_count strm

let generator_arg =
  Gram.Entry.of_parser "generator_arg" (fun strm ->
    match Stream.peek strm with
    | Some (KEYWORD "(", _) ->
        Stream.junk strm;
        Some (fetch_generator_arg 1 strm)
    | _ -> None)

DELETE_RULE Gram str_item: "module"; a_UIDENT; module_binding0 END;

EXTEND Gram
  GLOBAL: str_item sig_item;

  str_item:
    [[
      "TYPE_CONV_PATH"; conv_path = STRING ->
        set_conv_path conv_path;
        <:str_item< >>
    ]];

  generator: [[ id = LIDENT; arg = generator_arg -> (id, arg) ]];

  str_item:
    [[
      "type"; tds = type_declaration; "with"; drvs = LIST1 generator SEP "," ->
        set_conv_path_if_not_set _loc;
        <:str_item< type $tds$; $gen_derived_defs _loc tds drvs$ >>
    ]];

  str_item:
    [[
      "exception"; tds = constructor_declaration; "with";
      drvs = LIST1 generator SEP "," ->
        set_conv_path_if_not_set _loc;
        <:str_item< exception $tds$; $gen_derived_exn_defs _loc tds drvs$ >>
    ]];

  sig_item:
    [[
      "type"; tds = type_declaration; "with"; drvs = LIST1 generator SEP "," ->
        set_conv_path_if_not_set _loc;
        <:sig_item< type $tds$; $gen_derived_sigs _loc tds drvs$ >>
    ]];

  sig_item:
   [[
     "exception"; cd = constructor_declaration; "with";
     drvs = LIST1 generator SEP "," ->
       set_conv_path_if_not_set _loc;
       <:sig_item< exception $cd$; $gen_derived_exn_sigs _loc cd drvs$ >>
    ]];

  str_item:
    [[
      "module"; i = found_module_name; mb = module_binding0 ->
        pop_conv_path ();
        <:str_item< module $i$ = $mb$ >>
    ]];

END
