open Ocamlbuild_plugin
open Command

let _ = dispatch begin function
  | After_rules ->

    (* use camlp4 for syntax *)
    flag ["ocaml"; "compile" ; "use_camlp4"] & S[ A"-pp"; A"camlp4o"];
    flag ["ocaml"; "ocamldep"; "use_camlp4"] & S[ A"-pp"; A"camlp4o"];

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "nostdlib"] & S [A"-I"; A"lib/"; A"-nostdlib"];
    flag ["ocaml"; "pack"   ; "nostdlib"] & S [A"-I"; A"lib/"; A"-nostdlib"];

    (* use pa_mirage syntax extension *)
    flag ["ocaml"; "compile" ; "pa_lwt"] & S[A"-pp"; A"camlp4o -I syntax pa_lwt.cmo"];
    flag ["ocaml"; "ocamldep"; "pa_lwt"] & S[A"-pp"; A"camlp4o -I syntax pa_lwt.cmo"];

    (* add a dependency to the local pervasives *)
    dep ["ocaml"; "compile"; "need_pervasives"] ["lib/pervasives.cmi"];

  | _ -> ()
end

