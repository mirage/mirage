open Str
open Filename

let ochan = ref stdout

let raw_read_file fn =
  let f = open_in fn in
  let r = ref [] in
    (try
       while true do
         r := input_line f :: !r
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
    Printf.fprintf !ochan "%s\n" module_comment;
    if mli then (* .mli file *)
      Printf.fprintf !ochan "module %s : sig %s end\n"
        module_name module_text
    else if !previous_module = module_name then (* .ml after .mli *)
      Printf.fprintf !ochan "= struct %s end\n\n"
        module_text
    else (* just .ml file *)
      Printf.fprintf !ochan "module %s = struct %s end\n\n"
        module_name module_text;
    previous_module := module_name
    
let _ =
  Arg.(parse ["-o", Arg.String (fun s -> ochan := open_out s), ""] process_file "pack_in_one files")
