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

let list_files dir =
  let l = Bos.OS.Path.matches ~dotfiles:true Fpath.(dir / "$(file)") in
  match l with
  | Error (`Msg e) -> Fmt.kstrf Alcotest.fail "list_files: %s" e
  | Ok l ->
      List.sort String.compare
      @@ List.rev_map
           (fun x ->
             match Fpath.relativize ~root:dir x with
             | None -> assert false
             | Some d -> Fpath.to_string d)
           l

let root = Fpath.(v "test" / "functoria" / "e2e" / "app")

let build_root = Fpath.(v "_build" / "default" // root)

let config_ml = Fpath.(root / "config.ml")

let get_ok = function Ok x -> x | Error (`Msg e) -> Alcotest.fail e

let read_file file = get_ok @@ Bos.OS.File.read file

let clean () =
  get_ok @@ Bos.OS.Dir.delete ~recurse:true build_root;
  let files = list_files root in
  List.iter
    (fun f ->
      match Filename.basename f with
      | "app.ml" | "config.ml" -> ()
      | _ ->
          if Rresult.R.get_ok @@ Bos.OS.Dir.exists Fpath.(root / f) then ()
          else get_ok @@ Bos.OS.File.delete Fpath.(root / f))
    files

let test ?err_ppf ?help_ppf fmt =
  Fmt.kstrf
    (fun l ->
      let line = String.v ~len:80 (fun i -> if i mod 2 = 0 then '-' else '=') in
      let l = String.cuts ~empty:false ~sep:" " l @ [ "-vv" ] in
      Fmt.pr "@,%a@,%a %a@,%a@,%!"
        Fmt.(styled (`Fg `Cyan) string)
        line
        Fmt.(styled `Bold string)
        "[TEST]"
        Fmt.Dump.(list string)
        l
        Fmt.(styled (`Fg `Cyan) string)
        line;
      F0.Tool.run_with_argv ?err_ppf ?help_ppf (Array.of_list ("" :: l)))
    fmt

(* cut a man page into sections *)
let by_sections s =
  let lines = String.cuts ~sep:"\n" s in
  let return l =
    match List.rev l with [] -> assert false | h :: t -> (h, t)
  in
  let rec aux current sections = function
    | [] -> List.rev (return current :: sections)
    | h :: t ->
        if
          String.length h > 1
          && String.for_all (fun x -> Char.Ascii.(is_upper x || is_white x)) h
        then aux [ h ] (return current :: sections) t
        else aux (h :: current) sections t
  in
  aux [ "INIT" ] [] lines

let files = Alcotest.(slist string String.compare)

let test_configure () =
  clean ();
  (* check that configure generates the file in the right dir when
     --file is passed. *)
  Alcotest.(check files)
    "the usual files should be present before configure"
    [ "app.ml"; "config.ml" ] (list_files root);
  test "configure --file %a" Fpath.pp config_ml;
  Alcotest.(check files)
    "new files should be created in the source dir"
    [ "app.ml"; "config.ml"; "test.context"; ".merlin"; "dune" ]
    (list_files root);
  clean ();

  (* check that configure is writting the correct test.context
     file *)
  let test_config root cfg =
    F0.Tool.run_with_argv (Array.of_list cfg);
    let expected =
      (String.concat ~sep:"\n" @@ List.map String.Ascii.escape (List.tl cfg))
      ^ "\n"
    in
    let got = get_ok @@ Bos.OS.File.read Fpath.(v root / "test.context") in
    Alcotest.(check string)
      ("config should persist in " ^ root)
      (String.Ascii.escape_string expected)
      (String.Ascii.escape_string got)
  in

  test_config (Fpath.to_string root)
    [ ""; "configure"; "-vv"; "--file=" ^ Fpath.to_string config_ml ];
  clean ();

  (* check that `test help configure` and `test configure --help` have
     the same output. *)
  let b1 = Buffer.create 128 and b2 = Buffer.create 128 in
  test
    ~help_ppf:(Format.formatter_of_buffer b1)
    "help configure --file=%a --help=plain" Fpath.pp config_ml;
  test
    ~help_ppf:(Format.formatter_of_buffer b2)
    "configure --file=%a --help=plain" Fpath.pp config_ml;
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
  Alcotest.(check bool) "name should be present" true (List.mem_assoc "NAME" s4);
  Alcotest.(check bool)
    "synopsis should be present" true
    (List.mem_assoc "SYNOPSIS" s4)

let test_describe () =
  F0.Tool.run_with_argv
    [| ""; "describe"; "-vv"; "--file"; Fpath.to_string config_ml |]

let test_build () =
  (* default build *)
  test "configure --file %a" Fpath.pp config_ml;
  test "build --file %a" Fpath.pp config_ml;
  Alcotest.(check bool)
    "main.exe should be built" true
    (Sys.file_exists Fpath.(to_string (root / "main.exe")));
  clean ();

  (* test --output *)
  test "configure --file %a -o toto" Fpath.pp config_ml;
  test "build --file %a" Fpath.pp config_ml;
  Alcotest.(check bool)
    "toto.exe should be built" true
    (Sys.file_exists Fpath.(to_string (build_root / "toto.exe")));
  clean ()

let test_keys () =
  test "configure --file %a" Fpath.pp config_ml;
  test "build --file %a" Fpath.pp config_ml;
  Alcotest.(check string)
    "vote contains the default value: cat" "cat"
    (read_file Fpath.(build_root / "vote"));
  clean ();

  test "configure --file %a --vote=dog" Fpath.pp config_ml;
  test "build --file %a" Fpath.pp config_ml;
  Alcotest.(check string)
    "vote contains dog" "dog"
    (read_file Fpath.(build_root / "vote"));
  clean ()

let test_clean () =
  test "configure --file %a" Fpath.pp config_ml;
  test "clean --file %a" Fpath.pp config_ml;
  Alcotest.(check files)
    "clean should remove all the files" [ "app.ml"; "config.ml" ]
    (list_files root)

let test_cache () =
  let str = "foo;;bar;;;\n\nllll;;;sdaads;;\n\t\\0" in
  test "configure --file %a --vote=%s" Fpath.pp config_ml str;
  test "build --file %a" Fpath.pp config_ml;
  Alcotest.(check string)
    "cache is valid" str
    (read_file Fpath.(build_root / "vote"));
  clean ()

let test_help () =
  let help_ppf = Fmt.with_buffer (Buffer.create 10) in
  test ~help_ppf "help --help=plain"

let test_default () =
  let help_ppf = Fmt.with_buffer (Buffer.create 10) in
  test ~help_ppf ""

let suite =
  [
    ("configure", `Quick, test_configure);
    ("describe", `Quick, test_describe);
    ("build", `Quick, test_build);
    ("keys", `Quick, test_keys);
    ("clean", `Quick, test_clean);
    ("help", `Quick, test_help);
    ("default", `Quick, test_default);
    ("cache", `Quick, test_cache);
  ]

let () = Alcotest.run "functoria-runtime" [ ("full", suite) ]
