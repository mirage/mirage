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

exception Unmet_dependency of Files.file_type
exception Cyclic_dependency of Files.file_type list
exception Unknown_error

let find_local_cycle seen (target, deps) =
  let rec check_dep aux = function
    | (dep, hd :: tl) ->
	if dep = hd then
	  List.rev (hd :: aux)
	else
	  check_dep (hd :: aux) (dep, tl)
    | (dep, []) -> [] in
  let rec check_all_deps = function
    | hd :: tl -> 
	begin match check_dep [] (hd, seen) with
	  | [] -> check_all_deps tl
	  | end_of_cycle ->
	      hd :: target :: end_of_cycle
	end
    | [] -> [] in
    check_all_deps deps

let find_cycle all_dependencies =
  let make_full_dependency dep =
    try
      List.find (fun (tar,_) -> tar = dep) all_dependencies
    with Not_found -> raise (Unmet_dependency dep) in
  let rec check_deps seen = function
    | hd :: tl -> 
	begin match check_dependency seen hd with
	  | [] -> check_deps seen tl
	  | cycle -> cycle
	end
    | [] -> []
  and check_dependency seen (target, deps) =
    match find_local_cycle seen (target, deps) with
      |	[] ->
	  check_deps (target :: seen) 
	  (List.map make_full_dependency deps)
      | cycle -> cycle in
    List.rev (check_deps [] all_dependencies)

let raise_error deps =
  match find_cycle deps with
    | [] -> raise Unknown_error
    | cycle -> raise (Cyclic_dependency cycle)

let string_of_cycle cycle =
  let buf = Buffer.create 64 in
  let cycle = List.map Files.source_filename_of_file cycle in
  let rec buffer_of_cycle cycle =
    match cycle with
      | [dep] -> 
	  Printf.bprintf buf "%s" dep;
	  buffer_of_cycle []
      | dep :: rest ->
	  Printf.bprintf buf "%s -> " dep;
	  buffer_of_cycle rest
      | [] -> buf in
    Buffer.contents (buffer_of_cycle cycle)
