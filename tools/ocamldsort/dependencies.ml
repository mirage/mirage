(***********************************************************************)
(*                           ocamldsort                                *)
(*                                                                     *)
(*                 Copyright (C) 2002  Dimitri Ara                     *)
(*                                                                     *)
(* This program is free software; you can redistribute it and/or       *)
(* modify it under the terms of the GNU General Public License         *)
(* as published by the Free Software Foundation; either version 2      *)
(* of the License, or (at your option) any later version.              *)
(*                                                                     *)
(* This program is distributed in the hope that it will be useful,     *)
(* but WITHOUT ANY WARRANTY; without even the implied warranty of      *)
(* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       *)
(* GNU General Public License for more details.                        *)
(*                                                                     *)
(* You should have received a copy of the GNU General Public License   *)
(* along with this program; if not, write to the Free Software         *)
(* Foundation, Inc.,                                                   *)
(* 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.           *)
(***********************************************************************)
 
let rec change_unwanted_sources param target = function
  | hd :: tl ->
      let file =
	match (Params.to_sorting_strategy param, hd) with
	  | _, Files.Implementation _ -> hd
	  | Params.Sort_ml_mli, _ -> hd
	  | Params.Sort_ml, Files.Interface name ->
	      Files.Implementation name in
	if List.mem target (Params.to_files param) && file <> target
	then
	  file :: change_unwanted_sources param target tl
	else
	  change_unwanted_sources param target tl
  | [] -> []

let rec change_unwanted_files param = function
  | (target, sources) :: tl ->
      let keep_target = 
	match (Params.to_sorting_strategy param, target,
	       List.mem target (Params.to_files param)) with
	  | (_, _, false) -> false
	  | (Params.Sort_ml, Files.Interface _, true) -> false
	  | (Params.Sort_ml, Files.Implementation _, true) -> true
      	  | (Params.Sort_ml_mli, _, true) -> true in
	if keep_target then
	  (target, change_unwanted_sources param target sources) ::
	  change_unwanted_files param tl
	else
	  change_unwanted_files param tl
  | [] -> []

let rec add_independent_targets deps = function 
  | hd :: tl -> 
      if List.mem_assoc hd deps then
	add_independent_targets deps tl
      else
	add_independent_targets ((hd, []) :: deps) tl
  | [] -> deps

let get_dependencies param =
  let raw_deps = Dep_parse.parse_ocamldep (Params.to_stream param) in
(*   let _ = Dep_debug.print_deps raw_deps in *)
  let complete_deps =
    add_independent_targets raw_deps (Params.to_files param) in
    change_unwanted_files param complete_deps
