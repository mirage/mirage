open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools

let ps = Printf.sprintf

(* From ocamljs, the ocaml to javascript compiler by Jake Donham *)
module Ocamljs = struct

  let ocamljs = ref (A"ocamljs")

  let ocamljs_c tags arg out =
    let tags = tags++"ocaml"++"js" in
    Cmd (S [!ocamljs; A"-c"; T(tags++"compile");
            ocaml_ppflags tags; (* flags_of_pathname arg; *)
            ocaml_include_flags arg; A"-o"; Px out; P arg])

  let ocamljs_link flag tags deps out =
    Cmd (S [!ocamljs; flag; T tags;
            atomize_paths deps; (* flags_of_pathname out; *) A"-o"; Px out])

  let ocamljs_link_lib = ocamljs_link (A"-a")
  let ocamljs_link_prog = ocamljs_link N

  let js_lib_linker tags =
    if Tags.mem "ocamlmklib" tags then
      ocamlmklib tags (* XXX ocamlmkjslib? *)
    else
      ocamljs_link_lib tags

  let js_lib_linker_tags tags = tags++"ocaml"++"link"++"js"++"library"

  let ocamljs_p tags deps out =
    Cmd (S [!ocamljs; A"-pack"; T tags;
            atomize_paths deps; (* flags_of_pathname out; *) A"-o"; Px out])

  let js_compile_ocaml_implem ?tag ml cmjs env build =
    let ml = env ml and cmjs = env cmjs in
    prepare_compile build ml;
    ocamljs_c (tags_of_pathname ml++"implem"+++tag) ml cmjs

  let js_link_gen = link_gen "cmjs" "cmjsa" "cmjsa" ["cmjs"; "cmi"]

  let js_link = js_link_gen ocamljs_link_prog
    (fun tags -> tags++"ocaml"++"link"++"js"++"program")

  let js_library_link = js_link_gen js_lib_linker js_lib_linker_tags

  let js_library_link_modules =
    link_modules [("cmjs",[]); ("cmi",[])] "cmjs" "cmjsa" "cmjsa" js_lib_linker js_lib_linker_tags

(* from Ocaml_compiler *)
  let link_from_file link modules_file cmX env build =
    let modules_file = env modules_file in
    let contents_list = string_list_of_file modules_file in
    link contents_list cmX env build

  let js_library_link_mllib = link_from_file js_library_link_modules

  let js_pack_modules =
    pack_modules [("cmjs",["cmi"]); ("cmi",[])] "cmjs" "cmjsa" "cmjsa" ocamljs_p
      (fun tags -> tags++"ocaml"++"pack"++"js")

  let js_pack_mlpack = link_from_file js_pack_modules

  let () =

  (* copied from the ocamlc versions in Ocaml_commpiler. *)
    rule "ocaml: mlpack & cmjs* & cmi -> cmjs"
      ~tags:["ocaml"; "js"]
      ~prod:"%.cmjs"
      ~deps:["%.mli"; "%.cmi"; "%.mlpack"]
      (js_pack_mlpack "%.mlpack" "%.cmjs");

  (* this rule is a little hack; the right one is commented out below,
     but since apparently tags are not checked when picking a rule
     (??), the commented rule conflicts with the ocamlc one when
     trying to build a .cmi *)
    rule "ocaml: mlpack & cmjs* -> cmjs"
      ~tags:["ocaml"; "js"]
      ~prods:["%.cmjs"]
      ~dep:"%.mlpack"
      (js_pack_mlpack "%.mlpack" "%.cmjs");

  (* rule "ocaml: mlpack & cmjs* -> cmjs & cmi"
     ~tags:["ocaml"; "js"]
     ~prods:["%.cmjs"; "%.cmi"]
     ~dep:"%.mlpack"
     (js_pack_mlpack "%.mlpack" "%.cmjs");*)

    rule "ocaml: ml & cmi -> cmjs"
      ~tags:["ocaml"; "js"]
      ~prod:"%.cmjs"
      ~deps:["%.mli"(* This one is inserted to force this rule to be skiped when
                       a .ml is provided without a .mli *); "%.ml"; "%.ml.depends"; "%.cmi"]
      (js_compile_ocaml_implem "%.ml" "%.cmjs");

  (* see above *)
    rule "ocaml: ml -> cmjs"
      ~tags:["ocaml"; "js"]
      ~prods:["%.cmjs"]
      ~deps:["%.ml"; "%.ml.depends"]
      (js_compile_ocaml_implem "%.ml" "%.cmjs");

  (* rule "ocaml: ml -> cmjs & cmi"
     ~tags:["ocaml"; "js"]
     ~prods:["%.cmjs"; "%.cmi"]
     ~deps:["%.ml"; "%.ml.depends"]
     (js_compile_ocaml_implem "%.ml" "%.cmjs");*)

    rule "ocaml: cmjs* -> js"
      ~tags:["ocaml"; "js"; "program"]
      ~prod:"%.js"
      ~dep:"%.cmjs"
      (js_link "%.cmjs" "%.js");

    rule "ocaml: mllib & cmjs* -> cmja"
      ~tags:["ocaml"; "js"; "library"]
      ~prod:"%.cmjsa"
      ~dep:"%.mllib"
      (js_library_link_mllib "%.mllib" "%.cmjsa");

    rule "ocaml: cmo* -> cmjsa"
      ~tags:["ocaml"; "js"; "library"]
      ~prod:"%.cmjsa"
      ~dep:"%.cmjs"
      (js_library_link "%.cmjs" "%.cmjsa");

    flag ["ocaml"; "js"; "link"]
      (S (List.map (fun x -> A (x^".cmjsa")) !Options.ocaml_libs))
end

(* Rules for MPL *)
module MPL = struct

  let mpl_c tags arg out =
    Cmd (S [A"mplc"; A"-v"; T(tags++"mpl"); P arg; Sh">"; Px out])

  let mpl_compile mpl ml env build =
    let mpl = env mpl and ml = env ml in
    let tags = tags_of_pathname mpl in
    mpl_c tags mpl ml


  let () =
    rule "mpl: mpl -> ml"
      ~prod:"%.ml"
      ~dep:"%.mpl"
      (mpl_compile "%.mpl" "%.ml")
end


(* Rules for MIR *)
module Mir = struct

  let ocamlopt_link flag tags deps out =
    Cmd (S [!Options.ocamlopt; flag; forpack_flags out tags; T tags;
            atomize_paths deps; A"-o"; Px out])

  let native_output_obj =
    ocamlopt_link (A"-output-obj")

  let native_output_obj_tags tags =
    tags++"ocaml"++"link"++"native"++"library"

  let native_output_obj_modules =
    link_modules [("cmx",[!Options.ext_obj])] "cmx" "o"
      !Options.ext_lib native_output_obj native_output_obj_tags

  let native_output_obj_mir =
    Ocamljs.link_from_file native_output_obj_modules

  let () =
    rule "output-obj: mir -> o"
      ~prod:"%.o"
      ~dep:"%.mir"
      (native_output_obj_mir "%.mir" "%.o")
end

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

let ocamlc_where = run_and_read "ocamlc -where"

let site_lib x = "-I " ^ ocamlc_where ^ "/site-lib/" ^ x

let pp_mirage = "-I " ^ ocamlc_where ^ "/mirage/syntax" ^ " pa_mirage.cma"
let pp_str = "-I " ^ ocamlc_where ^ " str.cma"

let pp_pa_mirage = "camlp4o " ^ pp_str ^ " " ^ pp_mirage

let pp_jslib = site_lib "jslib" ^ " jslib.cma syntax_inline.cmo"
let pp_ulex  = site_lib "ulex" ^ " pa_ulex.cma ulexing.cma"
let pp_jslib_inline = "camlp4o " ^ pp_ulex ^ " " ^ pp_jslib

let os =
  let os = getenv "OS" ~default:"unix" in
  if os <> "unix" && os <> "xen" && os <> "browser" then
    (Printf.eprintf "`%s` is not a supported OS\n" os; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "OS: %s" os; os)

let lib =
  match os with
    | "unix" | "xen" -> "native"
    | "browser"      -> "js"
    | _              -> assert false

let make_lib file =
  match os with
    | "unix" | "xen" -> A (ps "%s.cmxa" file)
    | "browser"      -> A (ps "%s.cmjsa" file)
    | _              -> assert false

let make_pack file =
  match os with
    | "unix" | "xen" -> A (ps "%s.cmx" file)
    | "browser"      -> A (ps "%s.cmjs" file)
    | _              -> assert false

let _ = dispatch begin function
  | Before_options ->
    Options.exclude_dirs := [ "runtime"; "syntax"; "scripts"; "tools" ]

  | After_rules ->

    let oslib     = ps "lib/os/%s" os in
    let stdlib    = ps "lib/std/%s" lib in
    let socketlib = ps "lib/net/socket/%s" os in

    let libs = List.map make_lib
      [ "stdlib"; "lwt" ] in
    let packs = List.map make_pack
      [ "oS"; "nettypes";"flow"; 
        "type"; "xmlm"; "html"; "atom";
        "mpl"; "mlnet"; "http"; "dhcp"; "dns" ] in

    let mirage_flags =
      [A"-nostdlib"; A"-I"; A stdlib; A"-I"; A "lib/std/lwt";
        (* OS *)
        A"-I"; A oslib;
        (* Network *)
        A"-I"; A "lib/net/api";
        A"-I"; A "lib/net/mpl";
        A"-I"; A "lib/net/dns";
        A"-I"; A "lib/net/ether";
        A"-I"; A "lib/net/dhcp";
        A"-I"; A "lib/net/http";
        A"-I"; A socketlib;
        (* Misc *)
        A"-I"; A "lib/misc/atom";
        A"-I"; A "lib/misc/xml";
        A"-I"; A "lib/misc/html";
        (* Pre-processor *)
        A"-pp"; A pp_pa_mirage;
      ] in

    (* Define internal libraries *)
    ocaml_lib (ps "%s/stdlib" stdlib);
    ocaml_lib "lib/std/lwt/lwt";
    ocaml_lib (ps "%s/oS" oslib);
    ocaml_lib (ps "%s/flow" socketlib);
    ocaml_lib "lib/net/mpl/mpl";

    (* set the visibility of lib/net/ sub-directories *)
    Pathname.define_context "lib/net/mpl/protocols" ["lib/net/mpl"];
    List.iter
      (fun path ->
        let me = ps "lib/net/%s" path in
        Pathname.define_context me [me; oslib; "lib/net/mpl"; "lib/net/api"; "lib/net/ether"])
      [ "dhcp"; "ether"; "dns" ];
    Pathname.define_context "lib/net/http" ["lib/net/http"; socketlib; oslib];
    Pathname.define_context socketlib [oslib];

    Pathname.define_context "lib/os/xen" ["lib/os/xen"];
    Pathname.define_context "lib/os/unix" ["lib/os/unix"];
    Pathname.define_context "lib/os/browser" ["lib/os/browser"];

    dep ["ocaml"; "compile"; "need_pervasives"] [ps "%s/pervasives.cmi" stdlib];
    dep ["ocaml"; "compile"; "need_camlinternalOO"] [ps "%s/camlinternalOO.cmi" stdlib];
    dep ["ocaml"; "compile"; "use_mirage"] [ps "%s/stdlib.cmxa" stdlib];

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "nostdlib"] & A"-nostdlib";
    flag ["ocaml"; "pack"; "nostdlib"] & A"-nostdlib";

    (* Configure the mirage lib *)
    flag ["ocaml"; "compile"; "use_mirage"] & S mirage_flags;
    flag ["ocaml"; "pack"; "use_mirage"]    & S mirage_flags;
    flag ["ocaml"; "link"; "use_mirage"]    & S (mirage_flags @ libs @ packs);
    flag ["ocamldep"; "use_mirage"]         & S[A"-pp"; A pp_pa_mirage];

    (* use pa_mirage syntax extension *)
    flag ["ocaml"; "compile"; "pa_mirage"] & S[A"-pp"; A pp_pa_mirage];

    flag ["ocaml"; "js"; "compile"; "pkg_jslib.inline"] & S[A"-pp"; A pp_jslib_inline];
    flag ["ocaml"; "js"; "compile"] & S[A"-I"; A(site_lib "ocamljs"); A"ocamljs.cmjs"];

    flag ["ocamldep"; "pkg_jslib.inline"] & S[A"-pp"; A pp_jslib_inline];
    flag ["ocamldep"; "pa_mirage"] & S[A"-pp"; A pp_pa_mirage];

    flag ["ocaml"; "js"; "link"; "library"; "support_js"] & S[A"-cclib"; A"support.js"];
    flag ["ocaml"; "js"; "link"; "library"; "primitives_js"] & S[A"-cclib"; A"primitives.js"];

  | _ -> ()
end

;;
