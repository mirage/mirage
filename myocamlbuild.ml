open Ocamlbuild_plugin

let () = pflag ["ocaml"; "link"] "dontlink" (fun pkg -> S[A"-dontlink"; A pkg])
