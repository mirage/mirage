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

module Ocamlfind = struct
  let query package predicates =
    let predicates = match predicates with
      | `native -> "native"
      | `byte   -> "byte"
      | `syntax -> "preprocessor,syntax" in
    let incls =
      Util.run_and_read (sf "ocamlfind -query %s -predicates %s -r -i-format" package predicates) in
    let files =
      Util.run_and_read (sf "ocamlfind -query %s -predicates %s -r -a-format" package predicates) in
    String.concat " " (incls @ files)
end

let stdlib =
  Util.get_lib "std" ^ "/lib"

let dyntype_lib =
  Util.get_lib "dyntype" ^ "/lib"

let dyntype_syntax =
  Util.get_lib "dyntype" ^ "/syntax"

module Flags = struct

  let dyntype_includes =
    let deps = Ocamlfind.query "camlp4.quotations" `syntax in
    sf "%s -I %s pa_type_conv.cmo dyntype.cmo pa_dyntype.cmo" deps dyntype_syntax

  let cow_includes =
    sf "%s -I syntax str.cma pa_cow.cmo" dyntype_includes

  let camlp4 includes =
    sf "camlp4o %s" includes

  let stdlib = [
    A"-nostdlib"; A"-I"; A stdlib;
  ]

  let dyntype = [
    A"-I"; A"+camlp4"; A"-pp" ; A(camlp4 dyntype_includes);
    A"-I"; A dyntype_syntax;
  ]

  let cow = [
    A"-pp"; A (camlp4 cow_includes);
  ]

end

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "use_mirage_stdlib"] & S Flags.stdlib; 
    flag ["ocaml"; "pack"   ; "use_mirage_stdlib"] & S Flags.stdlib;

    (* use pa_dyntype syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_dyntype"] & S Flags.dyntype;
    flag ["ocaml"; "ocamldep"; "pa_dyntype"] & S Flags.dyntype;

    (* use pa_cow syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_cow"] & S Flags.cow;
    flag ["ocaml"; "ocamldep"; "pa_cow"] & S Flags.cow;

  | _ -> ()
end

