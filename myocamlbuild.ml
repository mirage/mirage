(* OASIS_START *)
(* OASIS_STOP *)
open Ocamlbuild_plugin
let () =
  pflag ["ocaml"; "link"] "dontlink" (fun pkg -> S[A"-dontlink"; A pkg]) ;;

dispatch dispatch_default;;
