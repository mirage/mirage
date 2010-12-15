open Ocamlbuild_plugin
open Command

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"; "nostdlib"] & S [A"-I"; A"lib/"; A"-nostdlib"];
    flag ["ocaml"; "pack"   ; "nostdlib"] & S [A"-I"; A"lib/"; A"-nostdlib"];

    List.iter (fun lib ->
      (* use pa_`lib` syntax extension if the _tags file specifies it *)
      flag ["ocaml"; "compile" ; "pa_" ^ lib] & S[A"-pp"; A (Printf.sprintf "camlp4o -I syntax pa_%s.cma" lib)];
      flag ["ocaml"; "ocamldep"; "pa_" ^ lib] & S[A"-pp"; A (Printf.sprintf "camlp4o -I syntax pa_%s.cma" lib)];
    ) [ "lwt"; "ulex" ];

    (* add a dependency to the local pervasives *)
    dep ["ocaml"; "compile"; "need_pervasives"] ["lib/pervasives.cmi"];

  | _ -> ()
end

