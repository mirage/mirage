open Ocamlbuild_plugin
open Command

let sf = Printf.sprintf

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
    with Not_found ->
      List.rev !x

  let split_nl s = split s '\n'

  let run_and_read x = split_nl (Ocamlbuild_pack.My_unix.run_and_read x)

  let get_lib lib =
    try 
      sf "%s/%s" (Sys.getenv "MIRAGELIB") lib
    with Not_found ->
      sf "../../../%s/_build" lib

  let os = try Sys.getenv "MIRAGEOS" with Not_found -> "unix"
  let flow = try Sys.getenv "MIRAGEFLOW" with Not_found -> "direct"

  let () = Options.build_dir := sf "_build/%s-%s" os flow

  let get_net_lib base =
    sf "../../../%s/_build/%s-%s" base os flow

end

let std_lib =
  Util.get_lib "std" ^ "/lib"

let std_syntax =
  Util.get_lib "std" ^ "/syntax"

let dyntype_lib =
  Util.get_lib "dyntype" ^ "/lib"

let dyntype_syntax =
  Util.get_lib "dyntype" ^ "/syntax"

let os_lib =
  let os = try Sys.getenv "MIRAGEOS" with Not_found -> "unix" in
  Util.get_lib "os" ^ (sf "/%s" os)

let net_lib =
  Util.get_lib (sf "net/%s" Util.flow) ^ "/" ^ Util.os

let http_lib =
  Util.get_net_lib "http"

let caml_lib =
  List.hd (Util.run_and_read "ocamlc -where")

module Flags = struct

  let camlp4_magic =
    "-parser Camlp4QuotationCommon -parser Camlp4OCamlRevisedQuotationExpander"

  let pa_dyntype_deps =
    sf "-I +camlp4 %s -I %s pa_type_conv.cmo dyntype.cmo pa_dyntype.cmo" camlp4_magic dyntype_syntax

  let pa_ulex_deps =
    sf "-I %s pa_ulex.cma" std_syntax

  let pa_lwt_deps =
    sf "-I %s pa_lwt.cma" std_syntax

  let pa_cow_deps =
    sf "%s %s %s -I syntax str.cma pa_cow.cmo" pa_ulex_deps pa_lwt_deps pa_dyntype_deps

  let camlp4 deps = [
    A"-pp"; A (sf "camlp4o %s" deps)
  ]

  let pa_dyntype = [
    A"-I"; A"+camlp4";
    A"-I"; A dyntype_syntax;
  ] @ camlp4 pa_dyntype_deps

  let pa_ulex = camlp4 pa_ulex_deps
  let pa_cow  = camlp4 pa_cow_deps

  let stdlib  = [ A"-nostdlib"; A"-I"; A std_lib; A "-I"; A os_lib; A "-I"; A net_lib; A "-I"; A http_lib ]
  let dyntype = [ A"-I"; A dyntype_lib ]
  let ulex    = [ A"-I"; A std_lib ]
  let cow     = [ A"-I"; A "lib" ]
  let http    = [ A"-I"; A http_lib ]

  let all_deps = [
    A"-ccopt"; A (sf "-L%s" caml_lib); A"-verbose";
    A"dyntype.cmx";
    A"ulex.cmxa";
    A"lwt.cmxa";
    A"oS.cmxa";
    A"http.cmxa";
    A"cow.cmx";
  ]

  let all =
    stdlib @ dyntype @ ulex @ http @ cow
end

module Expand = struct
  let camlp4o tags arg out =
    Cmd (S [A"camlp4o"; A"-printer"; A"o"; T(tags++"ocaml"++"camlp4"++"pa_exp"); P arg; Sh">"; Px out])

  let camlp4o_expand ml exp_ml env build =
    let ml = env ml and exp_ml = env exp_ml in
    let tags = tags_of_pathname ml in
    camlp4o tags ml exp_ml

  let () =
    rule "expand: ml -> _exp.ml"
      ~prod:"%_exp.ml"
      ~dep:"%.ml"
      (camlp4o_expand "%.ml" "%_exp.ml");
end

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "use_mirage_stdlib"] & S Flags.stdlib; 
    flag ["ocaml"; "pack"   ; "use_mirage_stdlib"] & S Flags.stdlib;

    (* use pa_dyntype syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_dyntype"] & S Flags.pa_dyntype;
    flag ["ocaml"; "ocamldep"; "pa_dyntype"] & S Flags.pa_dyntype;

    (* use http if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "use_http"] & S Flags.http;
    flag ["ocaml"; "ocamldep"; "use_http"] & S Flags.http;

    (* use pa_cow syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_cow"] & S Flags.pa_cow;
    flag ["ocaml"; "ocamldep"; "pa_cow"] & S Flags.pa_cow;
    flag ["ocaml"; "camlp4"  ; "pa_exp"] & Sh Flags.pa_cow_deps;

    (* use pa_cow syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "use_cow"]        & S Flags.all;
    flag ["ocaml"; "link" ; "native"; "use_cow"] & S (Flags.all @ Flags.all_deps);
    flag ["ocaml"; "ocamldep"; "use_cow"]        & S Flags.cow;

  | _ -> ()
end

