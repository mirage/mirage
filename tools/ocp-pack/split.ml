(***********************************************************************)
(*                                                                     *)
(*                TypeRex : OCaml Development Tools                    *)
(*                                                                     *)
(*                       OCamlPro S.A.S.                               *)
(*                                                                     *)
(*  Copyright 2011 OCamlPro SAS                                        *)
(*  All rights reserved.  This file is distributed under the terms of  *)
(*  the GNU Public License version 3.0.                                *)
(*                                                                     *)
(***********************************************************************)

let usage = "\
Usage:

  ocp-split <file.annot>

Options:
"

let version () =
  Printf.printf "\
ocp-split version %s-%s

Copyright (C) 2011 OCamlPro S.A.S.

This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

"
    Version.number Version.git_commit;
  exit 0

let prefix = ref ""
let verbose = ref false

let args = Arg.align [
  "-version", Arg.Unit version     , " Display version information";
  "-prefix" , Arg.Set_string prefix, "<string> Use a prefix when generating annot files";
  "-v"      , Arg.Set verbose      , " Display more information";
]

let filename = ref None

let ano str = match !filename with
  | Some _ ->
    Printf.eprintf "ERROR: specify only one input file\n";
    exit 2
  | None   ->
    if not (Sys.file_exists str) then begin
      Printf.eprintf "ERROR: cannot find %s" str;
      exit 2
    end else
      filename := Some str

let _ =
  Arg.parse args ano usage

let ic = match !filename with
  | Some f -> open_in f
  | None   ->
    Printf.eprintf "ERROR: you must specify an input file\n";
    exit 2

let files = ref []

let add_file f lines =
  if List.mem_assoc f !files then
    files := (f, lines @ List.assoc f !files) :: List.remove_assoc f !files
  else
    files := (f, lines) :: !files

let header line =
  try Scanf.sscanf line "%S %d %d %d %S %d %d %d" (fun f _ _ _ _ _ _ _ -> Some f)
  with _ -> None

let replace_prefix str =
    let i = String.rindex str '.' in
    (String.sub str 0 i) ^ ".annot"

let write_stuff (f, lines) =
  let file = Filename.concat !prefix (replace_prefix f) in
  if !verbose then Printf.printf "creating %s\n%!" file;
  let oc = open_out file in
  List.iter (fun line -> output_string oc (line ^ "\n")) (List.rev lines);
  close_out oc

let read_stuff () =
  let lines = ref [] in
  let file = ref "" in
  try while true do
    let line = input_line ic in
    match header line with
      | None   -> lines := line :: !lines;
      | Some f ->
        if !file <> "" then
          add_file !file !lines;
        file := f;
        lines := [line]
    done
  with _ ->
    if !file <> "" then
      add_file !file !lines;
    List.iter write_stuff !files

let _ =
  read_stuff ()


