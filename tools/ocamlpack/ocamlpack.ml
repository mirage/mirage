(* See included COPYING file for copyright, GPLv2 *)

open Str
open Filename
open Printf

let modname = ref "pack"

let no_source_lines = ref []

let strip_cr line =
  let l = String.length line in
    if l > 0 && line.[l-1] = '\r' then
      String.sub line 0 (l-1)
    else
      line

(* read file and insert preprocessor hints in each line *)
let raw_read_file fn =
  let f = open_in fn in
  let skip_src_lines = List.mem fn !no_source_lines in
  let num = ref 0 in
  let r = ref [] in
    (try
       while true do
         if not skip_src_lines then (
           incr num;
           r := sprintf "# %d \"%s/%s\"" !num !modname fn :: !r;
         );
         r := strip_cr (input_line f) :: !r
       done
     with End_of_file -> ());
    String.concat "\n" (List.rev !r)

(** returns (module_comment, remaining_module_text *)
let split_module_comment_and_text =
  let comment_start = regexp "^(\\*" in
  let comment_end   = regexp_string "*)" in
    fun module_text ->
      if string_match comment_start module_text 0 then begin
        ignore (search_forward comment_end module_text 0);
        (* ^ this can fail if comment isn't closed, but it is an error *)
        (String.sub module_text 0 (match_end ()),
         String.sub module_text (match_end ()) (String.length module_text - match_end ()))
      end
      else
        ("", module_text)

let module_name fn = String.capitalize (chop_extension (basename fn))

let rec process_files = function
  | mli :: ml :: tl when (ml ^ "i" = mli) ->
      (* mli followed by ml *)
      let mli_text = raw_read_file mli in
      let ml_text = raw_read_file ml in
      let _, mli_module_text = split_module_comment_and_text mli_text in
      let _, ml_module_text = split_module_comment_and_text ml_text in
      printf "module %s : sig\n%s\nend = struct\n%s\nend\n"
        (module_name mli) mli_module_text  ml_module_text;
      process_files tl
  | ml :: tl when (check_suffix ml ".ml") ->
      (* just an ML module *)
      let ml_text = raw_read_file ml in
      let _, ml_module_text = split_module_comment_and_text ml_text in
      printf "module %s = struct\n%s\nend\n" (module_name ml) ml_module_text;
      process_files tl
  | mli :: tl when (check_suffix mli ".mli") ->
      (* a module type MLI without a following ML *)
      let mli_text = raw_read_file mli in
      let _, mli_module_text = split_module_comment_and_text mli_text in
      printf "module type %s = sig\n%s\nend\n" (module_name mli) mli_module_text;
      process_files tl;
  | x :: tl ->
      failwith (sprintf "unknown file %s: must be .ml or .mli" x)
  | [] -> ()
    
let _ =
  let files = ref [] in
  Arg.(parse [
    "-name", Set_string modname, "top-level module name";
    "-no-source-lines", 
      String (fun s -> no_source_lines := s :: !no_source_lines), 
      "do not add source-code lines for this input file";
   ] (fun s -> files := s :: !files) "pack_in_one files");
  let files = List.rev !files in
  printf "(* This file has been auto-generated using ocamlpack and includes:\n";
  List.iter (fun x -> printf "      %s\n" x) files;
  printf " *)\n\n";
  process_files files
