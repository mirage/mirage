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
  let comment_start = regexp "^(\\*\\*" in
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

let previous_module = ref ""

let process_file fn =
  let module_name = String.capitalize (chop_extension (basename fn)) in
  let mli = check_suffix fn ".mli" in
  let text = raw_read_file fn in
  let module_comment, module_text = split_module_comment_and_text text in
    print_string module_comment; print_newline ();
    if mli then (* .mli file *)
      Printf.printf "module %s : sig\n%s\nend\n"
        module_name module_text
    else if !previous_module = module_name then (* .ml after .mli *)
      Printf.printf "= struct\n%s\nend\n\n"
        module_text
    else (* just .ml file *)
      Printf.printf "module %s = struct\n%s\nend\n\n"
        module_name module_text;
    previous_module := module_name
    
let _ =
  Printf.printf "(* This file has been auto-generated using ocamlpack *)\n\n";
  Arg.(parse [
    "-name", Set_string modname, "top-level module name";
    "-no-source-lines", 
      String (fun s -> no_source_lines := s :: !no_source_lines), 
      "do not add source-code lines for this input file";
   ] process_file "pack_in_one files")
