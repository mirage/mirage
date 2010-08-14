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

let print_dep (target, sources) =
  prerr_string (Files.filename_of_file target ^ ": ");
  List.iter (fun x -> prerr_string (Files.filename_of_file x ^ " ")) sources;
  prerr_endline ""

let print_deps deps =
  List.iter print_dep deps
