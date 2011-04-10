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
end

module Flags = struct

  let camlp4_magic =
    "-parser Camlp4QuotationCommon -parser Camlp4OCamlRevisedQuotationExpander"

  let pa_dyntype_deps =
    sf "-I +camlp4 %s pa_type_conv.cmo dyntype.cmo pa_dyntype.cmo" camlp4_magic 

  let pa_ulex_deps =
    sf "pa_ulex.cma" 

  let pa_lwt_deps =
    sf "pa_lwt.cma"

  let pa_cow_deps =
    sf "%s %s %s -I syntax str.cma pa_cow.cmo" pa_ulex_deps pa_lwt_deps pa_dyntype_deps

  let camlp4 deps = [
    A"-pp"; A (sf "camlp4o %s" deps)
  ]

  let pa_dyntype = [
    A"-I"; A"+camlp4";
  ] @ camlp4 pa_dyntype_deps

  let pa_ulex = camlp4 pa_ulex_deps
  let pa_cow  = camlp4 pa_cow_deps

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
    (* use pa_dyntype syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_dyntype"] & S Flags.pa_dyntype;
    flag ["ocaml"; "ocamldep"; "pa_dyntype"] & S Flags.pa_dyntype;

    dep ["pa_dyntype"] ["pa_type_conv.cma"; "pa_dyntype.cma"];
    (* use pa_cow syntax extension if the _tags file specifies it *)
    flag ["ocaml"; "compile" ; "pa_cow"] & S Flags.pa_cow;
    flag ["ocaml"; "ocamldep"; "pa_cow"] & S Flags.pa_cow;
    flag ["ocaml"; "camlp4"  ; "pa_exp"] & Sh Flags.pa_cow_deps;
  | _ -> ()
end

