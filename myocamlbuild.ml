(*
 * Copyright (c) 2010-2012 Anil Madhavapeddy <anil@recoil.org>
 * Copyright (c) 2010-2011 Thomas Gazagnaire <thomas@ocamlpro.com>
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
open Printf

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

(* XXX this wont work with a custom ocamlc not on the path *)
let ocaml_libdir = Util.run_and_read "ocamlc -where"

(* Configuration rules for packages *)
module Configure = struct
  (* Read a list of lines from files in _config/<arg> *)
  let config x =
    try string_list_of_file (Pathname.pwd ^ "/_config/" ^ x)
    with Sys_error _ ->
      eprintf "_config/%s not found: run ./configure first\n%!" x;
      exit 1

  (* Read a config file as a shell fragment to be appended directly. Repeat
   * lines are also filtered, but ordering preserved. *)
  let config_sh x = Sh (String.concat " " (config x))

  (* Test to see if a flag file exists *)
  let test_flag x = Sys.file_exists (sprintf "%s/_config/flag.%s" Pathname.pwd x)
  let if_opt fn a = if test_flag "opt" then List.map fn a else []
  let if_natdynlink fn a = if test_flag "opt" && test_flag "natdynlink" then List.map fn a else []

  (* Flags for building and using syntax extensions *)
  let ppflags () =
    (* Syntax extensions for the libraries being built *)
    flag ["ocaml"; "pp"; "use_syntax"] & S [config_sh "syntax.deps"];
    (* Include the camlp4 flags to build an extension *)
    flag ["ocaml"; "pp"; "build_syntax"] & S [config_sh "syntax.build"];
    flag ["ocaml"; "pp"; "build_syntax_r"] & S [config_sh "syntax.build.r"];
    (* NOTE: we cannot use the built-in use_camlp4, as that forces
     * camlp4lib.cma to be linked with the mllib target, which results
     * in a non-functioning extension as it will be loaded twice.
     * So this simply includes the directory, which leads to a working archive *)
    let p4incs = [A"-I"; A"+camlp4"] in
    flag ["ocaml"; "ocamldep"; "build_syntax"] & S p4incs;
    flag ["ocaml"; "compile"; "build_syntax"] & S p4incs;
    flag ["ocaml"; "ocamldep"; "build_syntax_r"] & S p4incs;
    flag ["ocaml"; "compile"; "build_syntax_r"] & S p4incs

  (* General flags for building libraries and binaries *)
  let libflags () =
    (* Include path for dependencies *)
    flag ["ocaml"; "ocamldep"] & S [config_sh "flags.ocaml"];
    flag ["ocaml"; "compile"] & S [config_sh "flags.ocaml"];
    flag ["ocaml"; "link"] & S [config_sh "flags.ocaml"];
    (* Include the -cclib for any C bindings being built *)
    let ccinc = List.flatten (List.map (fun x -> [A"-cclib"; A("-l"^x)]) (config "runtime")) in
    let dllinc = List.flatten (List.map (fun x -> [A"-dllib"; A("-l"^x)]) (config "runtime")) in
    flag ["link"; "library"; "native"; "ocaml"] & S ccinc;
    flag ["link"; "library"; "byte"; "ocaml"] & S dllinc

  (* Flags for building test binaries, which include just-built extensions and libs *)
  let testflags () =
    List.iter (ocaml_lib ~tag_name:"use_lib" ~dir:"lib") (List.map ((^)"lib/") (config "lib"));
    (* The test binaries also depend on the just-built libraries *)
    let lib_nc = List.map (fun x -> "lib/"^x-.-"cmxa") (config "lib") in
    let lib_bc = List.map (fun x -> "lib/"^x-.-"cma") (config "lib") in
    dep ["ocaml"; "native"; "use_lib"] lib_nc;
    dep ["ocaml"; "byte"; "use_lib"] lib_bc;
    let lib_nc_sh = config_sh "archives.native" :: (List.map (fun x -> P x) lib_nc) in
    let lib_bc_sh = config_sh "archives.byte" :: (List.map (fun x -> P x) lib_bc) in
    flag ["ocaml"; "link"; "native"; "program"] & S lib_nc_sh;
    flag ["ocaml"; "link"; "byte"; "program"] & S lib_bc_sh;
    flag ["ocaml"; "link"; "native"; "output_obj"] & S lib_nc_sh;
    flag ["ocaml"; "link"; "byte"; "output_obj"] & S lib_bc_sh;
    (* TODO gen native syntax.deps *)
    let syntax_bc = List.map (sprintf "syntax/%s.cma") (config "syntax") in
    let syntax_bc_use = List.map (fun x -> P x) syntax_bc in
    flag ["ocaml"; "pp"; "use_syntax"] & S syntax_bc_use;
    dep ["ocaml"; "ocamldep"; "use_syntax"] syntax_bc

  let flags () =
    ppflags ();
    libflags ();
    testflags ()

  (* Create an .all target based on _config flags *)
  let rules () =
    rule "build all targets: %.all contains what was built" ~prod:"%.all"
      (fun env builder ->
        let libs =
          let libs = List.map ((^)"lib/") (config "lib") in
          let interface = List.map (fun x -> x-.-"cmi") libs in
          let byte = List.map (fun x -> x-.-"cma") libs in
          let native = if_opt (fun x -> x-.-"cmxa") libs @ (if_opt (fun x -> x-.-"cmx") libs) in
          let nativea = if_opt (fun x -> x-.-"a") libs in
          let natdynlink = if_natdynlink (fun x -> x-.-"cmxs") libs in
          interface @ byte @ native @ natdynlink @ nativea in
        (* Build runtime libs *)
        let runtimes = List.map (sprintf "lib/lib%s.a") (config "runtime") @
            (List.map (sprintf "lib/dll%s.so") (config "runtime"))
        in
        (* Build syntax extensions *)
        let syntaxes =
          let syn = config "syntax" in
          let bc = List.map (fun x -> sprintf "syntax/%s.cma" x) syn in
          let nc = if_opt (fun x -> sprintf "syntax/%s.cmxa" x) syn in
          let ncs = if_natdynlink (fun x -> sprintf "syntax/%s.cmxs" x) syn in
          bc @ nc @ ncs in
        (* Any extra targets *)
        let extra = config "extra" in
        (* Execute the rules and echo everything built into the %.all file *)
        let targs = libs @ runtimes @ syntaxes @ extra in
        let out = List.map Outcome.good (builder (List.map (fun x -> [x]) targs)) in
        Echo ((List.map (fun x -> x^"\n") out), (env "%.all"))
      )
end

(* Rules to directly invoke GCC rather than go through OCaml. *)
module CC = struct

  let cc = getenv "CC" ~default:"cc"
  let ar = getenv "AR" ~default:"ar"
  let cflags = Configure.config_sh "cflags"

  let cc_call tags dep prod env builder =
    let dep = env dep and prod = env prod in
    let tags = tags_of_pathname dep++"cc"++"compile"++tags in
    let flags = [A"-c"; cflags] in
    let inc = A (sprintf "-I%s/%s" Pathname.pwd (Filename.dirname dep)) in
    Cmd (S (A cc :: inc :: flags @ [T tags; A"-o"; Px prod; P dep]))

  let cc_archive clib a path env builder =
    let clib = env clib and a = env a and path = env path in
    let objs = List.map (fun x -> path / x) (string_list_of_file clib) in
    let objs = List.map (fun x -> (Filename.chop_extension x)^".o") objs in
    let objs = List.map Outcome.good (builder (List.map (fun x -> [x]) objs)) in
    Cmd(S[A ar; A"rc"; Px a; T(tags_of_pathname a++"c"++"archive"); atomize objs])

  (** Copied from ocaml/ocamlbuild/ocaml_specific.ml and modified to add
      the output_obj tag *)
  let native_output_obj x =
    link_gen "cmx" "cmxa" !Options.ext_lib [!Options.ext_obj; "cmi"]
       ocamlopt_link_prog
      (fun tags -> tags++"ocaml"++"link"++"native"++"output_obj") x

  let bytecode_output_obj x =
    link_gen "cmo" "cma" !Options.ext_lib [!Options.ext_obj; "cmi"]
       ocamlc_link_prog
      (fun tags -> tags++"ocaml"++"link"++"byte"++"output_obj") x

  let rules () =
    rule "cc: %.c -> %.o" ~prod:"%.o" ~dep:"%.c" (cc_call "c" "%.c" "%.o");
    rule "cc: %.cc -> %.o" ~prod:"%.o" ~dep:"%.cc" (cc_call "c" "%.cc" "%.o");
    rule "cc: %.S -> %.o" ~prod:"%.o" ~dep:"%.S" (cc_call "asm" "%.S" "%.o");
    rule "archive: cclib .o -> .a archive"
      ~prod:"%(path:<**/>)lib%(libname:<*>).a"
      ~dep:"%(path)lib%(libname).cclib"
      (cc_archive "%(path)lib%(libname).cclib" "%(path)lib%(libname).a" "%(path)");
    (* Rule to link a module and output a standalone native object file *)
    rule "ocaml: cmx* & o* -> .m.o"
      ~prod:"%.m.o"
      ~deps:["%.cmx"; "%.o"]
      (native_output_obj "%.cmx" "%.m.o");
    (* Rule to link a module and output a standalone bytecode C file *)
    rule "ocaml: cmo* & o* -> .mb.c"
      ~prod:"%.mb.c"
      ~deps:["%.cmo"; "%.o"]
      (bytecode_output_obj "%.cmo" "%.mb.c")

  let flags () =
     flag ["cc";"depend"; "c"] & S [A("-I"^ocaml_libdir)];
     flag ["cc";"compile"; "c"] & S [A("-I"^ocaml_libdir)];
     flag ["cc";"compile"; "asm"] & S [A"-D__ASSEMBLY__"]
end

module Xen = struct
  (** Link to a standalone Xen microkernel *)
  let cc_xen_link bc tags arg out env =
    (* XXX check ocamlfind path here *)
    let xenlib = Util.run_and_read "ocamlfind query mirage" in
    let jmp_obj = Px (xenlib / "longjmp.o") in
    let head_obj = Px (xenlib / "x86_64.o") in
    let ocamllib = match bc with |true -> "ocamlbc" |false -> "ocaml" in
    let ld = getenv ~default:"ld" "LD" in
    let ldlibs = List.map (fun x -> Px (xenlib / ("lib" ^ x ^ ".a")))
      [ocamllib; "xen"; "xencaml"; "diet"; "m"] in
    Cmd (S ( A ld :: [ T(tags++"link"++"xen");
      A"-d"; A"-nostdlib"; A"-m"; A"elf_x86_64"; A"-T";
      Px (xenlib / "mirage-x86_64.lds");  head_obj; P arg ]
      @ ldlibs @ [jmp_obj; A"-o"; Px out]))

  let cc_xen_bc_link tags arg out env = cc_xen_link true tags arg out env
  let cc_xen_nc_link tags arg out env = cc_xen_link false tags arg out env

  (* Rewrite sections for Xen LDS layout *)
  let xen_objcopy dst src env builder =
    let dst = env dst in
    let src = env src in
    let cmd = ["objcopy";"--rename-section";".bss=.mlbss";"--rename-section";
      ".data=.mldata";"--rename-section";".rodata=.mlrodata";
      "--rename-section";".text=.mltext"] in
    let cmds = List.map (fun x -> A x) cmd in
    Cmd (S (cmds @ [Px src; Px dst]))

  (** Generic CC linking rule that wraps both Xen and C *)
  let cc_link_c_implem ?tag fn c o env build =
    let c = env c and o = env o in
    fn (tags_of_pathname c++"implem"+++tag) c o env

  let rules () =
    (* Rule to rename module sections to ml* equivalents for the static vmem layout *)
    rule "ocaml: .m.o -> .mx.o"
      ~prod:"%.mx.o"
      ~dep:"%.m.o"
      (xen_objcopy "%.mx.o" "%.m.o");

     (* Xen link rule *)
    rule ("final link: %.mx.o -> %.xen")
      ~prod:"%(file).xen"
      ~dep:"%(file).mx.o"
      (cc_link_c_implem cc_xen_nc_link "%(file).mx.o" "%(file).xen")

end

let _ = Options.make_links := false;;

let _ = dispatch begin function
  | Before_rules ->
     Configure.rules ();
     CC.rules ();
  | After_rules ->
     Configure.flags ();
     CC.flags ();
     Xen.rules ();
     (* Required to repack sub-packs (like Pa_css) into Pa_mirage *)
     pflag ["ocaml"; "pack"] "for-repack" (fun param -> S [A "-for-pack"; A param]);
     flag ["ocaml"; "pp"; "cow_no_open"] & S [A"-cow-no-open"]
  | _ -> ()
end
