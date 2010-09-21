(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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
 *
 *)

(* Command line tool to build Mirage applications *)

open Arg 
open Printf

type os = Unix | Xen | Browser
type mode = Tree | Installed
type net = Static | DHCP

(* binding for realpath(2) *)
external realpath: string -> string = "unix_realpath"
(* uname(3) bindings *)
external uname_os: unit -> string = "unix_sysname"
external uname_machine: unit -> string = "unix_sysmachine"

(* default arguments *)
let ocamldsort = ref "miragedsort.opt"
let ocamlopt = ref "ocamlopt.opt"
let ocamlopt_flags = "-nostdlib -annot"
let ocamljs_flags = "-nostdlib -annot"
let ocamljs_cclibs = ["primitives"; "support"; "console_stubs"; "clock_stubs"; "websocket_stubs"; "evtchn_stubs" ]
let ocamlopt_flags_extra = ref ""
let ocamldep = ref "ocamldep.opt"
let ocamljs = ref "ocamljs"
let cc = ref "gcc"
let os = ref Unix 
let mode = ref Tree
let net = ref DHCP
let modname = ref "app_main.t"

let set_key k fn f =
  let x = fn (String.lowercase f) in
  k := x

let set_os = set_key os 
  (function
   | "xen"|"x" -> Xen
   | "unix"|"u" -> Unix
   | "browser"|"b" -> Browser
   | f -> failwith (sprintf "Unknown -os '%s', needs to be unix|xen" f)
  )

let set_mode = set_key mode
  (function
   | "tree"|"t" -> Tree
   | "installed"|"i" -> Installed
   | f -> failwith (sprintf "Unknown -mode '%s', needs to be tree|installed" f)
  )

let set_net = set_key net
  (function
   | "dhcp"|"d" -> DHCP
   | "static"|"s" -> Static
   | f -> failwith (sprintf "Unknown -net '%s', needs to be dhcp|static" f)
  )

let set_var k r s = ("-" ^ k), Set_string r, (sprintf "%s (default: %s)" s !r)

let usage_str = sprintf "Usage: %s [options] <build dir>" Sys.argv.(0)

let cmd xs =
  let x = String.concat " " xs in
  let xcol = String.concat " " (("\027[36m" ^ (List.hd xs) ^ "\027[0m") :: (List.tl xs)) in
  eprintf "%s\n" xcol;
  match Sys.command x with 
  | 0 -> () 
  | n -> 
      eprintf "%s (exit %d)\n" x n; exit n

let _ =
  let build_dir = ref None in
  let keyspec = [
      "-os", String set_os, "Set target operating system [xen|unix|browser]";
      "-mode", String set_mode, "Set where to build application [tree|installed]";
      "-net", String set_net, "How to configure network interfaces [dhcp|static]";
      set_var "mod" modname "Application module name";
      set_var "cc" cc "Compiler to use";
      set_var "ocamldsort" ocamldsort "ocamldsort binary";
      set_var "ocamlopt" ocamlopt "ocamlopt binary";
      set_var "ocamljs" ocamlopt "ocamljs binary";
      set_var "ocamlopt_flags" ocamlopt_flags_extra "ocamlopt flags";
      set_var "ocamldep" ocamldep "ocamldep binary";
    ] in
  parse keyspec (fun s -> build_dir := Some s) usage_str;
  let mirage_root = match !mode with
    | Tree -> Sys.getcwd ()
    | Installed -> failwith "Installed mode not supported yet"
  in
  (* Various locations for syntax, standard library and other libraries *)
  let syntax = sprintf "%s/syntax" mirage_root in
  let stdlib = match !os with
    |Unix | Xen -> sprintf "%s/lib/stdlib" mirage_root 
    |Browser -> sprintf "%s/lib/stdlib.js" mirage_root in
  let libdir = sprintf "%s/lib" mirage_root in
  let templates = sprintf "%s/templates" mirage_root in

  (* Directory in which the mirage application resides *)
  let build_dir = match !build_dir with
   |None -> eprintf "No builddir specified\n"; Arg.usage keyspec usage_str; exit 1
   |Some x -> realpath x 
  in

  (* -pp flag to invoke the pa_mirage syntax extension *)
  let camlp4 = sprintf "-pp 'camlp4o -I %s pa_mirage.cma'" syntax in
  (* Core includes for stdlib and lwt needed by all applications *)
  let includes_pre = sprintf "-I %s -I %s/lwt" stdlib libdir in
  (* Includes for other packed libraries such as mlnet or mpl *)
  let includes_post = sprintf "-I %s/lib/obj" mirage_root in
  (* Includes for target-specific directory *)
  let includes_os = match !os with
    | Unix -> sprintf "-I %s/unix" libdir
    | Xen -> sprintf "-I %s/xen" libdir
    | Browser -> sprintf "-I %s/browser" libdir
  in
  (* All includes *)
  let includes = String.concat " " [ includes_pre; includes_os; includes_post ] in

  (* The list of standard libraries for a given OS *)
  let stdlibs = match !os with
    |Browser ->
      [ "stdlib"; "lwtlib"; "browser" ]
    |Xen ->
      [ "stdlib"; "lwtlib"; "mpl"; "mlnet"; "xen" ]
    |Unix ->
      [ "stdlib"; "lwtlib"; "mpl"; "mlnet"; "unix" ]
  in

  (* The other libraries needed by an OS (which will eventually be added on
     demand as required *)
  let otherlibs = match !os with
    |Browser -> []
    |Xen -> [ "mletherip"; "mltcp"; "mludp"; "mldns"; "mldhcp"; "io" ]
    |Unix -> [ "mletherip"; "mltcp"; "mludp"; "mldns"; "mldhcp"; "io" ]
  in

  let libext = match !os with
    |Browser -> "cmjsa"
    |Unix |Xen -> "cmxa"
  in

  (* Complete set of libraries needed *)
  let libs = String.concat " " (List.map
    (fun l -> sprintf "-I %s/%s %s.%s" libdir l l libext) (stdlibs @ otherlibs)) in

  (* If building on x86_64 Linux, use no-pic *)
  let ocamlopt_flags_os = match uname_os (), (uname_machine ()) with
    |"Linux", "x86_64" -> "-fno-PIC -nodynlink"
    |_ -> "" in

  let ocamlopt_debug = match !os with
    |Unix -> "-g"
    |Xen |Browser -> "" in

  (* Complete set of flags to ocamlopt *)
  let ocamlopt_flags = String.concat " " [ocamlopt_flags; ocamlopt_flags_os; ocamlopt_debug; !ocamlopt_flags_extra ] in

  Sys.chdir build_dir;

  (* Assemble the top-level module file *)
  (* XXX disabled for now 
  let top_module = sprintf "%s/mirage_build_main.ml" build_dir in
  let module_cats = String.concat " " (List.map (fun x -> sprintf "%s/%s.ml" templates x) [
     (match !os with Unix -> "unix" |Xen -> "xen");
     (match !net with DHCP -> "dhcp" |Static -> "static");
  ]) in
  cmd [ "cat" ; module_cats; ">"; top_module ];
  *)

  (* Go to the build directory and generate dependencies and read them in *)
  cmd [ !ocamldsort; camlp4; "-nox -mli *.ml *.mli > .depend" ];
  let depin = open_in ".depend" in
  let depends = input_line depin in
  close_in depin;
 
  (* Start OS-specific build *)
  match !os with
  | Xen ->
      let runtime = sprintf "%s/runtime/xen" mirage_root in
      (* Build the raw application object file *)
      cmd [ !ocamlopt; ocamlopt_flags; camlp4; includes; libs; depends; "-output-obj -o app_raw.o" ];
      (* Relink sections for custom memory layout *)
      cmd [ "objcopy --rename-section .data=.mldata --rename-section .rodata=.mlrodata --rename-section .text=.mltext app_raw.o app.o" ];
      (* Change to the Xen kernel build dir and perform build *)
      Sys.chdir (runtime ^ "/kernel");
      let app_lib = sprintf "APP_LIB=\"%s/app.o\"" build_dir in
      cmd [ "make"; app_lib ];
      let output_gz = sprintf "%s/kernel/obj/mirage-os.gz" runtime in
      let target_gz = sprintf "%s/mirage-os.gz" build_dir in
      let target_nongz = sprintf "%s/mirage-os" target_gz in
      (* Move the output kernel to the application build directory *)
      cmd [ "mv"; output_gz; target_gz ];
      (* Make an uncompressed version available for debugging purposes *)
      cmd [ "zcat"; target_gz; ">"; target_nongz ]

  | Unix -> 
      let runtime = sprintf "%s/runtime/unix" mirage_root in
      (* Build the raw application object file *)
      cmd [ !ocamlopt; ocamlopt_flags; camlp4; includes; libs; depends; "-output-obj -o app.o" ];
      (* Change the the Unix kernel build dir and perform build *)
      Sys.chdir (runtime ^ "/main");
      let app_lib = sprintf "APP_LIB=\"%s/app.o\"" build_dir in
      cmd [ "make"; app_lib ];
      let output_bin = sprintf "%s/main/app" runtime in
      let target_bin = sprintf "%s/mirage-unix" build_dir in
      cmd [ "mv"; output_bin; target_bin ]

  | Browser ->
      let runtime = sprintf "%s/runtime/browser" mirage_root in
      let console_html = sprintf "%s/app.html" runtime in
      let cclibs = String.concat " " (List.map (fun x -> sprintf "-cclib %s/%s.js" runtime x) ocamljs_cclibs) in
      (* Build the raw application object file *)
      cmd [ !ocamljs; ocamljs_flags; camlp4; includes; libs; cclibs; depends; "-o app.js" ];
      (* Copy in the console HTML *)
      cmd [ "cp"; console_html; build_dir ]

