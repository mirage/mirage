(* OASIS_START *)
(* OASIS_STOP *)
open Ocamlbuild_plugin
let () =
  pflag ["ocaml"; "link"] "dontlink" (fun pkg -> S[A"-dontlink"; A pkg]) ;;

let doc_intro = "index.text"

let () =
  dispatch
    (function hook ->
      dispatch_default hook ;
      match hook with
        | After_rules ->
            dep ["ocaml"; "doc"; "extension:html"] & [doc_intro] ;
            flag ["ocaml"; "doc"; "extension:html"] & S[A"-intro"; P doc_intro];
        | _ -> ()
    )
