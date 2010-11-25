open Ocamlbuild_plugin
open Command

let sf = Printf.sprintf
let lib x = sf "../../std/_build/%s" x

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib *)
    flag ["ocaml"; "compile"] & S [A"-I"; A (lib "lib"); A"-nostdlib"];
    flag ["ocaml"; "pack"   ] & S [A"-I"; A (lib "lib"); A"-nostdlib"];

    (* use pa_mirage syntax extension *)
    flag ["ocaml"; "compile" ; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cmo" (lib "syntax"))];
    flag ["ocaml"; "ocamldep"; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cmo" (lib "syntax"))];

  | _ -> ()
end

