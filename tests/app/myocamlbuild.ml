open Ocamlbuild_plugin

let incl p = flag ["ocaml"; "compile"] & S[A"-I"; A p]

let () = dispatch @@ function
  | After_rules ->
    incl "../../lib";
    incl "../../../lib"
  | _ -> ()
