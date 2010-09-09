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

exception Unknown_extension of string

type file_type = Interface of string | Implementation of string

let is_ml file = Filename.check_suffix file ".ml"
let is_mli file = Filename.check_suffix file ".mli"
let is_cmo file = Filename.check_suffix file ".cmo"
let is_cmi file = Filename.check_suffix file ".cmi"
let is_cmx file = Filename.check_suffix file ".cmx"
let is_interface file = is_mli file || is_cmi file
let is_implementation file = is_ml file || is_cmo file || is_cmx file

let file_of_filename file =   
  if is_implementation file then
    Implementation (Filename.chop_extension file)
  else if is_interface file then
    Interface (Filename.chop_extension file)
  else
    raise (Unknown_extension file)

let meta_filename_of_file implementation interface = function
  | Interface s -> s ^ interface
  | Implementation s -> s ^ implementation

let source_filename_of_file = meta_filename_of_file ".ml" ".mli"
let byte_filename_of_file = meta_filename_of_file ".cmo" ".cmi"
let opt_filename_of_file = meta_filename_of_file ".cmx" ".cmi"
let js_filename_of_file = meta_filename_of_file ".cmjs" ".cmi"

(* beware, it won't print the extension of the file *)
let filename_of_file = function
  | Interface s -> s
  | Implementation s -> s
