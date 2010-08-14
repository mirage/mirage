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

let remove_assocs keys list =
  List.filter (fun (key, _) -> not (List.mem key keys)) list

let remove_from_list to_remove list =
  List.filter (fun elt -> not (List.mem elt to_remove)) list
      
let rec remove_sources sources = function
  | (target, my_sources) :: tl ->
      (target, remove_from_list sources my_sources) :: 
      remove_sources sources tl
  | [] -> []

let rec get_independant_targets = function
  | (target, []) :: tl -> target :: get_independant_targets tl
  | hd :: tl -> get_independant_targets tl
  | [] -> []

let rec sort_module_dependencies = function
  | hd :: tl as dependencies ->
(*      let _ = Dep_debug.print_deps dependencies in*)
      let independant_targets = get_independant_targets dependencies in
      let new_dependencies =
	remove_sources
	  independant_targets
	  (remove_assocs independant_targets dependencies) in
	if new_dependencies = dependencies then
	  Dep_error.raise_error new_dependencies
	else
	  independant_targets @ sort_module_dependencies new_dependencies
  | [] -> []
      
let sort_dependencies_with_extension dependencies param =
  let files = Params.to_files param in
  let rec sort_dependencies_with_extension_aux = function
    | hd :: tl ->
	if List.mem hd files then
	  hd :: sort_dependencies_with_extension_aux tl
	else
	  sort_dependencies_with_extension_aux tl
    | [] -> [] in
    sort_dependencies_with_extension_aux 
      (sort_module_dependencies dependencies)
    
let sort_dependencies dependencies param = 
  sort_dependencies_with_extension dependencies param
