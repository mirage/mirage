open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools

let ps = Printf.sprintf

let os =
  let os = getenv "MIRAGEOS" ~default:"unix" in
  if os <> "unix" && os <> "xen" then
    (Printf.eprintf "`%s` is not a supported OS\n" os; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "OS: %s" os; os)

(* Points to the root of the installed Mirage stdlibs *)
let lib = getenv "MIRAGELIB"

let stdlib = ps "%s/std/lib" lib
let oslib = ps "%s/os/%s" lib os

(* Rules for MIR *)
module Mir = struct

  let link_from_file link modules_file cmX env build =
    let modules_file = env modules_file in
    let contents_list = string_list_of_file modules_file in
    link contents_list cmX env build

  let ocamlopt_link flag tags deps out =
    Cmd (S [!Options.ocamlopt; flag; T tags;
            atomize_paths deps; A"-o"; Px out])

  let native_output_obj =
    ocamlopt_link (A"-output-obj")

  let native_output_obj_tags tags =
    tags++"ocaml"++"link"++"native"++"library"

  let native_output_obj_modules =
    link_modules [("cmx",[!Options.ext_obj])] "cmx" "o"
      !Options.ext_lib native_output_obj native_output_obj_tags

  let native_output_obj_mir =
    link_from_file native_output_obj_modules

  let cc = ref (A"cc")
  let ocamlc_libdir = "-L" ^ (Lazy.force stdlib_dir)
  let oslib_unixrun = oslib ^ "/libunixrun.a"
  let oslib_unixmain = oslib ^ "/main.o"
  let cc_link tags arg out =
    let tags = tags++"cc"++"c" in
    Cmd (S (!cc :: [ T(tags++"link");
             A ocamlc_libdir;
             A"-lm"; A"-lasmrun";
             A oslib_unixrun;
             A"-o"; Px out; P arg;
             A oslib_unixmain]))

  let cc_link_c_implem ?tag c o env build =
    let c = env c and o = env o in
    cc_link (tags_of_pathname c++"implem"+++tag) c o

  let () =
    rule "output-obj: mir -> o"
      ~prod:"%.m.o"
      ~dep:"%.mir"
      (native_output_obj_mir "%.mir" "%.m.o");

    rule "final unix link: m.o -> .unix"
      ~prod:"%.unix"
      ~dep:"%.m.o"
      (cc_link_c_implem "%.m.o" "%.unix")
end

let _ = dispatch begin function
  | After_rules ->
    let pp_pa_lwt = ps "camlp4o %s/std/syntax/pa_lwt.cmo" lib in
    let libs = [A "stdlib.cmxa"; A "lwt.cmxa"; A "oS.cmxa"] in
    let mirage_flags =
      [A"-nostdlib"; A"-I"; A stdlib; A"-I"; A oslib; A"-pp"; A pp_pa_lwt] in

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "nostdlib"] & A"-nostdlib";
    flag ["ocaml"; "pack"; "nostdlib"] & A"-nostdlib";

    (* Configure the mirage lib *)
    flag ["ocaml"; "compile"] & S mirage_flags;
    flag ["ocaml"; "pack"]    & S mirage_flags;
    flag ["ocaml"; "link"]    & S (mirage_flags @ libs);
    flag ["ocamldep"]         & S[A"-pp"; A pp_pa_lwt];

    (* use pa_mirage syntax extension *)
    flag ["ocaml"; "compile"] & S[A"-pp"; A pp_pa_lwt];

  | _ -> ()
end
