open Ocamlbuild_plugin
open Command

let () = dispatch begin function
 | After_rules ->
     dep  ["link"; "ocaml"; "use_libcrunch"] ["libcrunch.a"]
 | _ -> ()
end
