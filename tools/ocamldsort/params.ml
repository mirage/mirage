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

type ocamldep =
    { path : string;
      load_path : string list;
      preprocessor : string option }

type input = Ocamldep of ocamldep | Input_file of string | Stdin

type file_output_type = Source | Byte | Opt | Js

type sorting_strategy = Sort_ml | Sort_ml_mli

type t = 
    { input : input;
      filenames : string list;
      files : Files.file_type list;
      sort_strat : sorting_strategy;
      output : file_output_type }

let to_sorting_strategy param = param.sort_strat
let to_input_param param = param.input
let to_filenames param = param.filenames
let to_files param = param.files
let to_file_output_type param = param.output

let to_path input_param = input_param.path
let to_load_path input_param =
  let buf = Buffer.create 256 in
    List.iter
      (fun x -> Printf.bprintf buf " -I %s" x)
      input_param.load_path;
    Buffer.contents buf
let to_preprocesor input_param =
  match input_param.preprocessor with
    | Some p -> "-pp '" ^ p ^ "'"
    | None -> ""
let to_concatened_filenames param =
  String.concat " " (to_filenames param)

let to_command_line param =
  match param.input with
    | Ocamldep input_param ->
	Printf.sprintf "%s %s %s %s"
	(to_path input_param)
	(to_load_path input_param)
	(to_preprocesor input_param)
	(to_concatened_filenames param)
    | _ -> failwith "to_command_line"

let to_stream param = 
  match (to_input_param param) with
    | Ocamldep _ ->
	let ic = Unix.open_process_in
		   (to_command_line param) in
	  at_exit (fun () -> close_in ic);
	  Stream.of_channel ic
    | Input_file file ->
	let ic = open_in file in
	  at_exit (fun () -> close_in ic);
	  Stream.of_channel ic
    | Stdin ->
	Stream.of_channel stdin

let filename_of_file param =
  match to_file_output_type param with
      Source -> Files.source_filename_of_file
    | Byte -> Files.byte_filename_of_file
    | Opt -> Files.opt_filename_of_file
    | Js -> Files.js_filename_of_file

let new_file_input_param file =
  Input_file file
    
let new_ocamldep_input_param path load_path preprocessor =
  let ocamldep = { path = path;
		   load_path = load_path;
		   preprocessor = preprocessor } in
    Ocamldep ocamldep
  
let new_param input_param filenames sort_strat output =
  { input = input_param;
    filenames = filenames;
    files = List.map Files.file_of_filename filenames;
    sort_strat = sort_strat;
    output = output; }
