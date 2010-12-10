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

module Flags = struct

  let stdlib  = [ A"-nostdlib"; A"-I"; A std_lib; ]

  let camlp4_magic =
    "-parser Camlp4QuotationCommon -parser Camlp4OCamlRevisedQuotationExpander -parser Camlp4GrammarParser"

  let camlp4 = [
    A"-I"; A"+camlp4";
    A"-pp"; A (sf "camlp4o %s" camlp4_magic)
  ]

end

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "use_mirage_stdlib"] & S Flags.stdlib; 
    flag ["ocaml"; "pack"   ; "use_mirage_stdlib"] & S Flags.stdlib;

    (* use pa_std syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_std"] & S Flags.camlp4;
    flag ["ocaml"; "ocamldep"; "pa_std"] & S Flags.camlp4;

  | _ -> ()
end

