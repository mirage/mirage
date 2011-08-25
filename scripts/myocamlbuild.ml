(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2010-2011 Thomas Gazagnaire <thomas@gazagnaire.org>
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

open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools

let ps = Printf.sprintf

(* This decides the global OS backend. It could be moved into explicit
   dependencies in the future, but for now is set as an environment
   variable *)
let os =
  let os = getenv "MIRAGEOS" ~default:"unix" in
  if os <> "unix" && os <> "xen" && os <> "node" then
    (Printf.eprintf "`%s` is not a supported OS\n" os; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "OS: %s" os; os)

(* This decides which Flow module to use (direct or socket) *)
let flow = 
  let flow = getenv "MIRAGEFLOW" ~default:"direct" in
  if flow <> "direct" && flow <> "socket" then
    (Printf.eprintf "`%s` is not a supported Flow type\n" flow; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "Flow: %s" flow; flow)

(* Points to the root of the installed Mirage stdlibs *)
let lib = getenv "MIRAGELIB"

let libdir =
  let root = getenv "MIRAGELIB" in
  let subdir = match os,flow with
  |"unix","socket" -> "unix-socket"
  |"unix","direct" -> "unix-direct"
  |"xen" ,"direct" -> "xen"
  |"node","socket" -> "node-socket"
  |_ -> Printf.eprintf "%s-%s is not a supported kernel combination\n" os flow; exit (-1) in
  ps "%s/%s/lib" root subdir
 
let syntaxdir = 
  ps "%s/syntax" (getenv "MIRAGELIB")

(* Utility functions (e.g. to execute a command and return lines read) *)
module Util = struct
  let split s ch =
    let x = ref [] in
    let rec go s =
      let pos = String.index s ch in
      x := (String.before s pos)::!x;
      go (String.after s (pos + 1))
    in
    try
      go s
    with Not_found -> !x

    let split_nl s = split s '\n'

    let run_and_read x = List.hd (split_nl (Ocamlbuild_pack.My_unix.run_and_read x))
end

(* OS detection *)
module OS = struct

  type u = Linux | Darwin
  type t = Unix of u | Xen | Node
  let host = match String.lowercase (Util.run_and_read "uname -s") with
    | "linux"  -> Unix Linux
    | "darwin" -> Unix Darwin
    | os -> Printf.eprintf "`%s` is not a supported host OS\n" os; exit (-1)
  let target = match String.lowercase os with
    | "unix" -> host (* Map the target to the current host, as cross-compiling is no use *)
    | "xen"  -> Xen
    | "node" -> Node
    | x -> failwith ("unknown target os: " ^ x)
end

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

  let native_output_obj_mir module_name =
    native_output_obj_modules [module_name]

  let cc = ref (A"cc")
  let ld = ref (A"ld")
  let ocamlc_libdir = "-L" ^ (Lazy.force stdlib_dir)
  let oslib = libdir 
  let oslib_unixrun = oslib ^ "/libunixrun.a"
  let oslib_unixmain = oslib ^ "/main.o"

  let cc_unix_link tags arg out =
    let dl_libs = match OS.host with
      |OS.Xen            -> assert false
      |OS.Node
      |OS.Unix OS.Linux  -> [A"-lm"; A"-ldl"; A"-lasmrun"; A"-lcamlstr"]
      |OS.Unix OS.Darwin -> [A"-lm"; A"-lasmrun"; A"-lcamlstr"] in
    let tags = tags++"cc"++"c" in
    Cmd (S (!cc :: [ T(tags++"link");
             A ocamlc_libdir;
             A"-o"; Px out; 
             A oslib_unixmain;
             P arg;
             A oslib_unixrun;
           ] @ dl_libs))

  let cc_xen_link tags arg out =
    let xenlib = libdir in   
    let head_obj = Px (xenlib / "x86_64.o") in
    let ldlibs = List.map (fun x -> Px (xenlib / ("lib" ^ x ^ ".a")))
      ["ocaml"; "xen"; "xencaml"; "diet"; "m"] in
    Cmd (S ( !ld :: [ T(tags++"link"++"xen");
      A"-d"; A"-nostdlib"; A"-m"; A"elf_x86_64"; A"-T";
      Px (xenlib / "mirage-x86_64.lds"); head_obj; P arg ]
      @ ldlibs @ [A"-o"; Px out]))
 
  let cc_link_c_implem ?tag fn c o env build =
    let c = env c and o = env o in
    fn (tags_of_pathname c++"implem"+++tag) c o

  let js_of_ocaml ?tag byte js env build =
    let byte = env byte and js = env js in
    Cmd (S [ A"js_of_ocaml"; A (ps "%s/mirage.js" libdir) ; Px js; A"-o"; Px byte ])

  let ml_main mirfile mlprod main_module env build =
    let mirfile = env mirfile in
    let mains = string_list_of_file mirfile in
    let mlprod = env mlprod in
    let main_module = env main_module in
    Echo ((List.map (ps "let _ = OS.Main.run (%s ())\n") mains), mlprod)

  (* Copied from ocaml/ocamlbuild/ocaml_specific.ml and modified to add
     the output_obj tag *)
  let native_output_obj x =
    link_gen "cmx" "cmxa" !Options.ext_lib [!Options.ext_obj; "cmi"]
       ocamlopt_link_prog
      (fun tags -> tags++"ocaml"++"link"++"native"++"output_obj") x

  let () =
    (* Copied from ocaml/ocamlbuild/ocaml_specific.ml *)
    let ext_obj = !Options.ext_obj in
    let x_o = "%"-.-ext_obj in

    rule "exec_ml: %.mir -> %__.ml"
      ~prod:"%__.ml"
      ~dep:"%.mir"
      (ml_main "%.mir" "%__.ml" "%__");

    (* Rule to link a module and output a standalone object file *)
    rule "ocaml: cmx* & o* -> .m.o"
      ~tags:["ocaml"; "native"; "output_obj"]
      ~prod:"%.m.o"
      ~deps:["%.cmx"; x_o]
      (native_output_obj "%.cmx" "%.m.o");

    rule ("final link: %__.m.o -> %.xen")
      ~prod:"%.xen"
      ~dep:"%__.m.o"
      (cc_link_c_implem cc_xen_link "%.m.o" "%.xen");

    rule ("final link: %__.m.o -> %.bin")
      ~prod:"%.bin"
      ~dep:"%__.m.o"
      (cc_link_c_implem cc_unix_link "%__.m.o" "%.bin");

    rule ("final link: %__.byte -> %.js")
      ~prod:"%.js"
      ~dep:"%__.byte"
      (js_of_ocaml "%.js" "%__.byte");

end

let lib file =
  if OS.target = OS.Node then
    A (file ^ ".cma")
  else
    A (file ^ ".cmxa")

(* All the syntax extensions *)
let pp_pa =
  let pa_std = ps "-I %s pa_ulex.cma pa_lwt.cma" syntaxdir in
  let pa_quotations = "-I +camlp4 -parser Camlp4QuotationCommon -parser Camlp4OCamlRevisedQuotationExpander" in
  let pa_dyntype = ps "%s -I %s pa_type_conv.cmo dyntype.cmo pa_dyntype.cmo" pa_quotations syntaxdir in
  let pa_cow = ps "%s -I %s str.cma pa_cow.cmo" pa_dyntype syntaxdir in
  let pa_bitstring = ps "-I %s pa_bitstring.cma" syntaxdir in
  ps "camlp4o %s %s %s" pa_std pa_cow pa_bitstring

(* Apply the global option *)
let _ =
  Options.ocaml_ppflags := [pp_pa]

let _ = dispatch begin function
  | After_rules ->
   let node_cclib = [
      A"-dllpath"; A Mir.oslib; A"-dllib"; A"-los";
      A"-cclib"; A"-los" ] in
    let mirage_flags = [ A"-nostdlib"; A"-I"; A libdir; ] in
    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "nostdlib"] & A"-nostdlib";
    flag ["ocaml"; "pack"   ; "nostdlib"] & A"-nostdlib";

    (* link with dummy libnode when needed *)
    flag ["ocaml"; "byte"; "program"] & S node_cclib;

    (* Configure the mirage lib *)
    flag ["ocaml"; "compile"] & S mirage_flags;
    flag ["ocaml"; "pack"]    & S mirage_flags;
    flag ["ocaml"; "link"]    & S mirage_flags;
    flag ["ocamldep"]         & S[A"-pp"; A pp_pa];

  | _ -> ()
end
