open Ocamlbuild_plugin
let () =
  pflag ["ocaml"; "link"] "dontlink" (fun pkg -> S[A"-dontlink"; A pkg]) ;;

let doc_intro = "doc/index.text"

let () = dispatch (function
    | After_rules ->
      dep ["ocaml"; "doc"; "extension:html"] & [doc_intro] ;
      flag ["ocaml"; "doc"; "extension:html"] & S[A"-intro"; P doc_intro];
    | _ -> ()
  )
