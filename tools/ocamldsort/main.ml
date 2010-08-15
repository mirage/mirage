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

let load_path = ref []
let preprocessor = ref None
let filenames = ref []
let ocamldep = ref "ocamldep.opt"
let sort_strat = ref Params.Sort_ml
let no_x = ref false

let output = ref Params.Source

let add_filename filename =
  filenames := filename :: !filenames

let usage = "Usage: ocamldsort [options] <files>"
let version =  "ocamldsort 0.14.4"
let print_version () = print_endline version; exit 0

let is_input_a_tty () =
  try
    ignore (Unix.tcgetattr Unix.stdin);
    true
  with _ ->
    false

let speclist = [
  "-I", Arg.String (fun dir -> load_path := !load_path @ [dir]),
  " <dir>\tadd <dir> to the list of include directories";
  "-pp", Arg.String (fun s -> preprocessor := Some s),
  "<command>\tpipe sources through preprocessor <command>";
  "-d", Arg.String (fun s -> ocamldep := s),
  " <command>\tuse <command> to do ocamldep job";
  "-mli", Arg.Unit (fun () -> sort_strat := Params.Sort_ml_mli),
  "  sort files using .mli dependencies";
  "-nox", Arg.Unit (fun () -> no_x := true),
  "  ignore filename containing `*\'";
  "-obj", Arg.Unit (fun () -> output := Params.Byte),
  "  print bytecode filename (.cmo and .cmi) (deprecated: use -byte)";
  "-byte", Arg.Unit (fun () -> output := Params.Byte),
  " print bytecode filename (.cmo and .cmi)";
  "-opt", Arg.Unit (fun () -> output := Params.Opt),
  "  print opt filename (.cmx and .cmi)";
  "-v", Arg.Unit print_version,
  "    output version information and exit" ] 

let fatal_error str =
  prerr_endline str;
  exit 1

let _ =
  try
    Arg.parse speclist add_filename usage; 
    if !no_x then
      filenames := 
      List.filter (fun x -> not (String.contains x '*')) !filenames;
    let input_param =
      if is_input_a_tty () then
	Params.new_ocamldep_input_param !ocamldep !load_path !preprocessor
    else 
      Params.Stdin in
    let param = Params.new_param input_param !filenames !sort_strat !output in
    let deps = Dependencies.get_dependencies param in
    let sorted = Dep_sort.sort_dependencies deps param in
    let named = List.map (Params.filename_of_file param) sorted in (* TODO *)
      match named with
	| [] -> ()
	| sorted -> print_endline (String.concat " " sorted)
 with 
   | Dep_error.Cyclic_dependency cyclic_deps ->
       fatal_error ("Error: cyclic dependencies: " ^ 
		    (Dep_error.string_of_cycle cyclic_deps))
   | Dep_error.Unmet_dependency dep -> fatal_error
       ("Error: unmet dependency: " ^ Files.source_filename_of_file dep)
   | Files.Unknown_extension file ->
       fatal_error ("Error: what kind of file " ^ file ^ " is?")
   | Dep_parse.Parse_error ->
       fatal_error "Error: error while parsing ocamldep output"
   | exc ->
       fatal_error ("Error: " ^ (Printexc.to_string exc))
