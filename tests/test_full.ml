(*
 * Copyright (c) 2015 Jeremy Yallop
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

open Astring
module Cmd = Functoria_command_line

let list_files dir =
  let dir = Fpath.v dir in
  let l = Bos.OS.Path.matches ~dotfiles:true Fpath.(dir / "$(file)") in
  match l with
  | Error (`Msg e) -> Fmt.kstrf Alcotest.fail "list_files: %s" e
  | Ok l ->
    List.sort String.compare @@
    List.rev_map (fun x ->
        match Fpath.relativize ~root:dir x with
        | None   -> assert false
        | Some d -> Fpath.to_string d
      ) l

let get_ok = function
  | Ok x           -> x
  | Error (`Msg e) -> Alcotest.fail e

let read_file file = get_ok @@ Bos.OS.File.read Fpath.(v file)

let clean_app () =
  get_ok @@ Bos.OS.Dir.delete ~recurse:true Fpath.(v "app/_build");
  let files = list_files "app" in
  List.iter (fun f ->
      match Filename.basename f with
      | "app.ml" | "config.ml" | "myocamlbuild.ml" -> ()
      | _ ->
        if Sys.is_directory (Filename.concat "app" f) then ()
        else get_ok @@ Bos.OS.File.delete Fpath.(v "app" / f)
    ) files

let clean_build () =
  get_ok @@ Bos.OS.Dir.delete ~recurse:true Fpath.(v "custom_build_")

let test ?err_ppf ?help_ppf fmt =
  Fmt.kstrf (fun l ->
      let l = String.cuts ~sep:" " l in
      Test_app.run_with_argv ?err_ppf ?help_ppf (Array.of_list ("" :: l))
    ) fmt

(* cut a man page into sections *)
let by_sections s =
  let lines = String.cuts ~sep:"\n" s in
  let return l = match List.rev l with
    | []   -> assert false
    | h::t -> h, t
  in
  let rec aux current sections = function
    | []     -> List.rev (return current :: sections)
    | h :: t ->
      if String.length h > 1
      && String.for_all (fun x -> Char.Ascii.(is_upper x || is_white x)) h
      then
        aux [h] (return current :: sections) t
      else
        aux (h :: current) sections t
  in
  aux ["INIT"] [] lines

let files = Alcotest.(slist string String.compare)

let test_configure () =
  clean_app ();
  (* check that configure generates the file in the right dir when
     --file is passed. *)
  Alcotest.(check files) "the usual files should be present before configure"
    ["app.ml"; "config.ml"; "myocamlbuild.ml"] (list_files "app");
  test "configure -vv --file app/config.ml";
  Alcotest.(check files) "new files should be created in the source dir"
    ["app.ml"; "config.ml"; "myocamlbuild.ml"; "key_gen.ml";
     "main.ml"; ".mirage.config"; "jbuild"; "_build"
    ] (list_files "app");
  clean_app ();

  (* check that configure generates the file in the right dir when
     --build-dir is passed. *)
  let files = Alcotest.(slist string String.compare) in
  Alcotest.(check files) "the usual files should be present before configure"
    ["app.ml"; "config.ml"; "myocamlbuild.ml"] (list_files "app");
  test "configure -vv --file app/config.ml --build-dir custom_build_";
  Alcotest.(check files) "only _build should be created in the source dir"
    ["app.ml"; "config.ml"; "myocamlbuild.ml"; "_build"]
    (list_files "app");
  Alcotest.(check files) "other files should be created in custom_build_"
    ["main.ml"; "app.ml"; ".mirage.config"; "jbuild"; "key_gen.ml";
     "myocamlbuild.ml" (* FIXME: add a .mirage-ignore file to avoid this *) ]
    (list_files "custom_build_");
  clean_build ();

  (* check that configure is writting the correct .mirage.config
     file *)
  let test_config root cfg =
    Test_app.run_with_argv (Array.of_list cfg);
    let expected = String.concat ~sep:"\n" @@ List.map String.Ascii.escape cfg in
    let got = get_ok @@ Bos.OS.File.read Fpath.(v root / ".mirage.config") in
    Alcotest.(check string) ("config should persist in " ^ root)
      (String.Ascii.escape_string expected )
      (String.Ascii.escape_string got)
  in

  test_config "custom_build_"
    [""; "configure"; "-vv"; "--file=app/config.ml"; "--build-dir=custom_build_"];
  clean_build ();

  test_config "app"
    [""; "configure"; "-vv"; "--file=app/config.ml"];
  clean_app ();

  (* check that `test help configure` and `test configure --help` have
     the same output. *)
  let b1 = Buffer.create 128 and b2 = Buffer.create 128 in
  test ~help_ppf:(Format.formatter_of_buffer b1)
    "help configure --file=app/config.ml --help=plain";
  test ~help_ppf:(Format.formatter_of_buffer b2)
    "configure --file=app/config.ml --help=plain";
  let s1 = Buffer.contents b1 and s2 = Buffer.contents b2 in

  let s1 = by_sections s1 and s2 = by_sections s2 in
  Alcotest.(check (list string))
    "help messages have the same configure options"
    (List.assoc "CONFIGURE OPTIONS" s1)
    (List.assoc "CONFIGURE OPTIONS" s2);
  Alcotest.(check (list string))
    "help messages have the same application parameters"
    (List.assoc "APPLICATION OPTIONS" s1)
    (List.assoc "APPLICATION OPTIONS" s2);
  Alcotest.(check (list string))
    "help messages have the same common options"
    (List.assoc "COMMON OPTIONS" s1)
    (List.assoc "COMMON OPTIONS" s2);

  (* check that `test help configure` works when no config.ml file
     is present. *)
  let b3 = Buffer.create 128 in
  let b4 = Buffer.create 128 in
  test "help configure --help=plain"
    ~err_ppf:(Format.formatter_of_buffer b3)
    ~help_ppf:(Format.formatter_of_buffer b4);
  let s3 = Buffer.contents b3 in
  let s4 = by_sections (Buffer.contents b4) in
  Alcotest.(check string) "no errors" s3 "";
  Alcotest.(check bool) "name should be present"
    true (List.mem_assoc "NAME" s4);
  Alcotest.(check bool) "synopsis should be present"
    true (List.mem_assoc "SYNOPSIS" s4)

let test_describe () =
  Test_app.run_with_argv
    [| ""; "describe"; "-vv";
       "--file"; "app/config.ml"|]

let test_build () =
  clean_app ();
  (* default build *)
  test "configure --file app/config.ml";
  test "build -vv --file app/config.ml";
  Alcotest.(check bool) "main.exe should be built" true
    (Sys.file_exists "app/main.exe");
  clean_app ();

  (* test --output *)
  test "configure --file app/config.ml -o toto";
  test "build -vv --file app/config.ml";
  Alcotest.(check bool) "toto.exe should be built" true
    (Sys.file_exists "app/toto.exe");
  clean_app ();

  (* test --build-dir *)
  test "configure -vv --file app/config.ml --build-dir custom_build_";
  test "build -vv --file app/config.ml --build-dir custom_build_";
  Alcotest.(check bool) "main.exe should be built in custom_build_" true
    (Sys.file_exists "custom_build_/main.exe");
  clean_build ();

  (* test --output + --build-dir *)
  test "configure --file app/config.ml --build-dir custom_build_ -o toto";
  test "build -vv --build-dir custom_build_ --file app/config.ml";
  Alcotest.(check bool) "toto.exe should be built in custom_build_" true
    (Sys.file_exists "custom_build_/toto.exe");
  clean_build ()

let test_keys () =
  clean_app ();
  test "configure -vv --file app/config.ml";
  test "build -vv --file app/config.ml";
  Alcotest.(check string) "vote contains the default value: cat" "cat"
    (read_file "app/vote");
  clean_app ();

  clean_build ();
  test "configure --file app/config.ml --build-dir custom_build_";
  test "build --file app/config.ml --build-dir custom_build_";
  Alcotest.(check string) "vote contains the default value: cat" "cat"
    (read_file "custom_build_/vote");
  clean_build ();

  clean_app ();
  test "configure --file app/config.ml --vote=dog";
  test "build --file app/config.ml";
  Alcotest.(check string) "vote contains dog" "dog" (read_file "app/vote");
  clean_app ()

let test_clean () =
  test "configure -vv --file app/config.ml";
  test "clean -vv --file app/config.ml";
  Alcotest.(check files) "clean should remove all the files"
    ["app.ml"; "config.ml"; "myocamlbuild.ml"]
    (list_files "app");

  test "configure -vv --file app/config.ml --build-dir=custom_build_";
  test "clean -vv --file app/config.ml --build-dir custom_build_";
  Alcotest.(check files) "clean should remove all the files"
    []
    (list_files "root")

let test_cache () =
  let str = "foo;;bar;;;\n\nllll;;;sdaads;;\n\t\\0" in
  test "configure --file app/config.ml --vote=%s" str;
  test "build --file app/config.ml";
  Alcotest.(check string) "cache is valid" str (read_file "app/vote")

let test_help () =
  test "help -vv --help=plain"

let test_default () =
  test "-vv"

let suite = [
  "configure"     , `Quick, test_configure;
  "describe"      , `Quick, test_describe;
  "build"         , `Quick, test_build;
  "keys"          , `Quick, test_keys;
  "clean"         , `Quick, test_clean;
  "help"          , `Quick, test_help;
  "default"       , `Quick, test_default;
  "cache"         , `Quick, test_cache;
]

let () = Alcotest.run "functoria-runtime" ["full", suite]
