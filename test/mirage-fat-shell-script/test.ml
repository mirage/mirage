let with_fmt_str k =
  let buf = Buffer.create 0 in
  let fmt = Format.formatter_of_buffer buf in
  k fmt;
  Format.pp_print_flush fmt ();
  Buffer.contents buf

let redact_line n s =
  (* At the moment it is not possible to inject argv & time so we remove the
   * generated line.
   * See https://github.com/mirage/functoria/pull/159 *)
  let lines = String.split_on_char '\n' s in
  let redacted_lines =
    List.mapi (fun i line -> if i + 1 = n then "# REDACTED" else line) lines
  in
  String.concat "\n" redacted_lines

let print_banner s =
  print_endline s;
  print_endline @@ String.make (String.length s) '=';
  print_newline ()

let test_output_fat =
  Mirage.FS.fat_shell_script ~block_file:"BLOCK_FILE" ~dir:(Fpath.v "DIR")
    ~regexp:"REGEXP"

let () =
  let tests = [ ("output_fat", test_output_fat) ] in
  List.iter
    (fun (name, f) ->
      print_banner name;
      print_endline @@ with_fmt_str f)
    tests
