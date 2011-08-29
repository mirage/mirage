(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2010-2011 Thomas Gazagnaire <thomas@gazagnaire.org>

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
open Printf

(* Points to the root of the installed Mirage stdlibs *)
let home = getenv ~default:"/usr/bin" "HOME"
let lib = getenv ~default:(home / "mir-inst") "MIRAGELIB"
let cc = getenv ~default:"cc" "CC"
let ld = getenv ~default:"ld" "LD"

(** Utility functions (e.g. to execute a command and return lines read) *)
module Util = struct
  let split s ch =
    let x = ref [] in
    let rec go s =
      try
        let pos = String.index s ch in
        x := (String.before s pos)::!x;
        go (String.after s (pos + 1))
      with Not_found -> x := s :: !x
    in
    go s;
    List.rev !x

    let split_nl s = split s '\n'

    let run_and_read x = List.hd (split_nl (Ocamlbuild_pack.My_unix.run_and_read x))
end

(** Host OS detection *)
module OS = struct

  type unix = Linux | Darwin
  type arch = X86_32 | X86_64

  let host =
    match String.lowercase (Util.run_and_read "uname -s") with
    | "linux"  -> Linux
    | "darwin" -> Darwin
    | os -> eprintf "`%s` is not a supported host OS\n" os; exit (-1)

  let arch =
    match String.lowercase (Util.run_and_read "uname -m") with
    | "x86_32"  -> X86_32
    | "x86_64" -> X86_64
    | arch -> eprintf "`%s` is not a supported arch\n" arch; exit (-1)

  let js_of_ocaml_installed =
    try
      Ocamlbuild_pack.My_unix.run_and_read "which js_of_ocaml" <> ""
    with _ -> false
end

(* Rules for building from a .mir build *)
module Mir = struct

  (** Link to a UNIX executable binary *)
  let cc_unix_link tags arg out env =
    let ocamlc_libdir = "-L" ^ (Lazy.force stdlib_dir) in
    let open OS in
    let unixrun mode = lib / mode / "lib" / "libunixrun.a" in
    let unixmain mode = lib / mode / "lib" / "main.o" in
    let mode = sprintf "unix-%s" (env "%(mode)") in
    let dl_libs = match host with
      |Linux  -> [A"-lm"; A"-ldl"; A"-lasmrun"; A"-lcamlstr"]
      |Darwin -> [A"-lm"; A"-lasmrun"; A"-lcamlstr"] in
    let tags = tags++"cc"++"c" in
    Cmd (S (A cc :: [ T(tags++"link"); A ocamlc_libdir; A"-o"; Px out; 
             A (unixmain mode); P arg; A (unixrun mode); ] @ dl_libs))

  (** Link to a standalone Xen microkernel *)
  let cc_xen_link tags arg out env =
    let xenlib = lib / "xen" / "lib" in   
    let head_obj = Px (xenlib / "x86_64.o") in
    let ldlibs = List.map (fun x -> Px (xenlib / ("lib" ^ x ^ ".a")))
      ["ocaml"; "xen"; "xencaml"; "diet"; "m"] in
    Cmd (S ( A ld :: [ T(tags++"link"++"xen");
      A"-d"; A"-nostdlib"; A"-m"; A"elf_x86_64"; A"-T";
      Px (xenlib / "mirage-x86_64.lds"); head_obj; P arg ]
      @ ldlibs @ [A"-o"; Px out]))

  (** Generic CC linking rule that wraps both Xen and C *) 
  let cc_link_c_implem ?tag fn c o env build =
    let c = env c and o = env o in
    fn (tags_of_pathname c++"implem"+++tag) c o env

  (** Invoke js_of_ocaml from .byte file to Javascript *)
  let js_of_ocaml ?tag byte js env build =
    let byte = env byte and js = env js in
    let libdir = lib / "node" / "lib" in
    Cmd (S [ A"js_of_ocaml"; P (libdir / "mirage.js") ; Px js; A"-o"; Px byte ])

  (** Generate an ML entry point file that spins up the Mirage runtime *)
  let ml_main mirfile mlprod env build =
    let mirfile = env mirfile in
    let mains = string_list_of_file mirfile in
    let mlprod = env mlprod in
    Seq [ (* XXX not sure if bug or feature, but Echo doesnt mkdir_p *)
      Cmd (S[A"mkdir"; A"-p"; Px (Pathname.dirname mlprod)]);
      Echo ((List.map (sprintf "let _ = OS.Main.run (%s ())\n") mains), mlprod)
    ]

  (** Copied from ocaml/ocamlbuild/ocaml_specific.ml and modified to add
      the output_obj tag *)
  let native_output_obj x =
    link_gen "cmx" "cmxa" !Options.ext_lib [!Options.ext_obj; "cmi"]
       ocamlopt_link_prog
      (fun tags -> tags++"ocaml"++"link"++"native"++"output_obj") x

  (** Generate all the rules for mir *)
  let rules () =
    (* Copied from ocaml/ocamlbuild/ocaml_specific.ml *)
    let ext_obj = !Options.ext_obj in
    let x_o = "%"-.-ext_obj in

    (* Generate the source stub that calls OS.Main.run *)
    rule "exec_ml: %.mir -> %__.ml"
      ~prod:"%(backend)/%(file)__.ml"
      ~dep:"%(file).mir"
      (ml_main "%(file).mir" "%(backend)/%(file)__.ml");

    (* Rule to link a module and output a standalone native object file *)
    rule "ocaml: cmx* & o* -> .m.o"
      ~prod:"%.m.o"
      ~deps:["%.cmx"; x_o]
      (native_output_obj "%.cmx" "%.m.o");

    (* Xen link rule *)
    rule ("final link: xen/%__.m.o -> xen/%.xen")
      ~prod:"xen/%(file).xen"
      ~dep:"xen/%(file)__.m.o"
      (cc_link_c_implem cc_xen_link "xen/%(file)__.m.o" "xen/%(file).xen");

    (* UNIX link rule *)
    rule ("final link: %__.m.o -> %.unix-%(mode).bin")
      ~prod:"unix-%(mode)/%(file).bin"
      ~dep:"unix-%(mode)/%(file)__.m.o"
      (cc_link_c_implem cc_unix_link "unix-%(mode)/%(file)__.m.o" "unix-%(mode)/%(file).bin");

    (* Node link rule *)
    rule ("final link: node/%__.byte -> node/%.js")
      ~prod:"node/%.js"
      ~dep:"node/%__.byte"
      (js_of_ocaml "node/%.js" "node/%__.byte");
end

(** Testing specifications module *)
module Spec = struct
  (** Supported Mirage backends *)
  type backend =  
   |Xen
   |Node
   |Unix_direct
   |Unix_socket

  (** Spec file describing the test and dependencies *)
  type t = {
    backends: backend list;
  }

  let backend_of_string = function
    |"xen" -> Xen 
    |"unix-direct" -> Unix_direct
    |"node" -> Node 
    |"unix-socket" -> Unix_socket
    |x -> failwith ("unknown backend: " ^ x)

  let backend_to_string = function
    |Xen -> "xen"
    |Node -> "node"
    |Unix_direct -> "unix-direct"
    |Unix_socket -> "unix-socket"

  (* List of all supported backends on this build host *)
  let all_backends =
    let open OS in
    let xen = match host,arch with
    |Linux, X86_64 -> [Xen]
    |_ -> [] in
    let node = if OS.js_of_ocaml_installed then [Node] else [] in
    [Unix_socket; Unix_direct] @ xen @ node

  let backends_iter fn spec = List.iter fn spec.backends
  let backends_map fn spec = List.map fn spec.backends

  (* Get the build target of a given backend *)
  let backend_target be name =
    let dir = backend_to_string be in
    match be with
    |Xen -> sprintf "%s/%s.xen" dir name 
    |Node -> sprintf "%s/%s.js" dir name
    |Unix_direct |Unix_socket -> sprintf "%s/%s.bin" dir name

  (** Spec file contains key:value pairs: 

    backend:node,xen,unix-direct
    backend:* (short form of above)
    no backend key results in "backend:*" being default

    *)
  let parse file = 
    let lines = string_list_of_file file in
    let kvs = List.map (fun line ->
      match Util.split line ':' with
      |[k;v] -> (String.lowercase k), (String.lowercase v)
      |_ -> failwith (sprintf "unknown spec entry '%s'" line)
    ) lines in
    let backends =
      try (match List.assoc "backend" kvs with
       |"*" -> all_backends
       |backends -> List.map backend_of_string (Util.split backends ',')
      ) with Not_found -> all_backends
    in {backends}

  let rules () =
    rule "build and execute spec backend target"
      ~prod:"%(test).%(backend).exec"
      ~dep:"%(test).spec"
      (fun env build ->
        let backend = backend_of_string (env "%(backend)") in
        (* Build the target for this backend *)
        let prod = env "%(test).%(backend).exec" in
        let binary = backend_target backend (env "%(test)") in
        let _ = List.map Outcome.ignore_good (build [[ binary ]]) in
        (* Execute the binary using the mir-run wrapper and log its output to prod *)
        Cmd (S [A "mir-run"; A"-b"; A backend; A"-o"; prod; A binary])
      );
    rule "build and execute all supported backend targets"
     ~prod:"%(test).exec"
     ~dep:"%(test).spec"
     (fun env build ->
       let test = env "%(test)" in
       let spec = parse (env "%(test).spec") in
       let _ = List.map Outcome.ignore_good (build (backends_map 
         (fun be -> [sprintf "%s.%s.exec" test (backend_to_string be)]) spec)) in
       Nop
     )
end

(* Alias source files into their repsective backend/ subdirs *)
let () =
  let source_exts = [".ml"; ".mli"; ".mll"; ".mly"] in
  List.iter (fun ext ->
    let prod = "%(backend)/%(file)"^ext and dep = "%(file)"^ext in
    rule (sprintf "alias from %%.%s -> <backend>/%%.%s" ext ext)
      ~prod ~dep (fun env build -> cp (env dep) (env prod))
  ) source_exts

(* XXX tag_file in ocamlbuild forces quotes around the filename,
   preventing globs such as <xen/**> from tagging subdirectories.
   We define tag_glob as a workaround *)
let tag_glob glob tags =
  Ocamlbuild_pack.Configuration.parse_string
    (sprintf "<%s>: %s" glob (String.concat ", " tags))

let _ = dispatch begin function
  | Before_hygiene ->
    (* Flag all the backend subdirs with a "backend:" tag *)
    List.iter (fun be ->
      let be = Spec.backend_to_string be in
      let betag = sprintf "backend:%s" be in
      tag_glob (sprintf "%s/**" be) [betag];
    ) Spec.all_backends

  | After_options ->
    let syntaxdir = lib / "syntax" in
    let pp_pa =
      let pa_inc = sprintf "-I %s -I +camlp4" syntaxdir in
      let pa_std = "pa_ulex.cma pa_lwt.cma" in
      let pa_quotations = "-parser Camlp4QuotationCommon -parser Camlp4OCamlRevisedQuotationExpander" in
      let pa_dyntype = sprintf "%s pa_type_conv.cmo dyntype.cmo pa_dyntype.cmo" pa_quotations in
      let pa_cow = sprintf "%s str.cma pa_cow.cmo" pa_dyntype in
      let pa_bitstring = "pa_bitstring.cma" in
      (* XXX pa_js also needed here *)
      sprintf "camlp4o %s %s %s %s" pa_inc pa_std pa_cow pa_bitstring
    in
    Options.ocaml_ppflags := [pp_pa]

  | After_rules -> begin
    (* do not compile with the standard lib *)
    let std_flags = S [ A"-nostdlib"; A"-annot" ] in
    flag ["ocaml"; "compile"] & std_flags;
    flag ["ocaml"; "pack"] & std_flags;
    flag ["ocaml"; "link"] & std_flags;
    (* Include the correct stdlib depending on which backend is chosen *)
    List.iter (fun be ->
      let be = Spec.backend_to_string be in
      let betag = sprintf "backend:%s" be in
      flag ["ocaml"; "compile"; betag] & S [A"-I"; Px (lib / be / "lib")];
      flag ["ocaml"; "pack"; betag] & S [A"-I"; Px (lib / be / "lib")];
      flag ["ocaml"; "link"; betag] & S [A"-I"; Px (lib / be / "lib")];
    ) Spec.all_backends;
    Mir.rules ();
    Spec.rules ();
    (* Link with dummy libnode when needed *)
    let node_cclib = [ A"-dllpath"; Px (lib/"node"/"lib"); A"-dllib";
      A"-los"; A"-cclib"; A"-los" ] in
    flag ["ocaml"; "byte"; "program"; "backend:node"] & S node_cclib;

  end
  | _ -> ()
end


