open Ocamlbuild_plugin
open Command

let sf = Printf.sprintf
let lib p x =
  try
    sf "%s/%s/%s" (Sys.getenv "MIRAGELIB") p x
  with Not_found ->
    sf "../../../../%s/_build/%s" p x

let mplc =
  try
    sf "%s/../bin/mplc" (Sys.getenv "MIRAGELIB") 
  with Not_found ->
    "../../../../../tools/mpl/mplc" 

let stdlib = lib "std"
(* Set the build directory to reflect the OS chosen,
   as they do not have compatible interfaces *)
let os = try Sys.getenv "MIRAGEOS" with Not_found -> "unix"
let oslib =
  Options.build_dir := "_build/"^os;
  lib "os" os

(* Rules for MPL *)
module MPL = struct

  let mpl_c tags arg out =
    Cmd (S [A mplc; A"-q"; T(tags++"mpl"); P arg; Sh">"; Px out])

  let mpl_compile mpl ml env build =
    let mpl = env mpl and ml = env ml in
    let tags = tags_of_pathname mpl in
    mpl_c tags mpl ml

  let () =
    rule "mpl: mpl -> ml"
      ~prod:"%.ml"
      ~dep:"%.mpl"
      (mpl_compile "%.mpl" "%.ml")
end

let _ = dispatch begin function
  | After_rules ->

    (* do not compile and pack with the standard lib, and point to right OS module *)
    flag ["ocaml"; "compile"] & S [A"-annot"; A"-I"; A (stdlib "lib"); A"-nostdlib"; A"-I"; A oslib];
    flag ["ocaml"; "pack"   ] & S [A"-I"; A (stdlib "lib"); A"-nostdlib"];
    pflag ["ocaml"; "pack"] "for-pack" (fun param -> S [A "-for-pack"; A param]);

    (* use pa_lwt syntax extension if needed *)
    flag ["ocaml"; "compile" ; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cma" (stdlib "syntax"))];
    flag ["ocaml"; "ocamldep"; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cma" (stdlib "syntax"))];

  | _ -> ()
end
