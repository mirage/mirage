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
      sf "../../%s/_build" lib
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

let os_runtime_lib = 
  let os = try Sys.getenv "MIRAGEOS" with Not_found -> "unix" in
  Util.get_lib "os" ^ (sf "/runtime_%s" os)

let net_lib =
  let os = try Sys.getenv "MIRAGEOS" with Not_found -> "unix" in
  sf "%s/%s" (Util.get_lib "net") os

let cow_syntax =
  Util.get_lib "cow" ^ "/syntax"

let cow_lib =
  Util.get_lib "cow" ^ "/lib"

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
    sf "%s %s %s -I %s str.cma pa_cow.cmo" pa_ulex_deps pa_lwt_deps pa_dyntype_deps cow_syntax

  let camlp4 deps = [
    A"-pp"; A (sf "camlp4o %s" deps)
  ]

  let pa_cow  = [
    A"-I"; A"+camlp4";
  ] @ camlp4 pa_cow_deps

  let stdlib  = [ A"-nostdlib"; A"-I"; A std_lib; ]
  let dyntype = [ A"-I"; A dyntype_lib ]
  let ulex    = [ A"-I"; A std_lib ]
  let cow     = [ A"-I"; A cow_lib ]
  let os      = [ A"-I"; A os_lib ]
  let net     = [ A"-I"; A net_lib ]

  let all =
    stdlib @ dyntype @ ulex @ os @ net @ cow
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

    (* use pa_cow syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ] & S (Flags.pa_cow @ Flags.all);
    flag ["ocaml"; "ocamldep"] & S Flags.pa_cow;
    flag ["ocaml"; "camlp4"  ] & Sh Flags.pa_cow_deps;

  | _ -> ()
end

