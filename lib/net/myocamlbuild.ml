open Ocamlbuild_plugin
open Command

let sf = Printf.sprintf
let lib x = sf "../../std/_build/%s" x
let oslib x = sf "../../os/_build/lib_%s" x

(* Rules for MPL *)
module MPL = struct

  let mpl_c tags arg out =
    Cmd (S [A"mplc"; A"-v"; T(tags++"mpl"); P arg; Sh">"; Px out])

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

    let os = "unix" in (* TODO xen et al *)
    Pathname.define_context "mpl/protocols" ["mpl"];
    Pathname.define_context "ether" ["mpl"; "api"];
    Pathname.define_context "dns" ["mpl"];
    Pathname.define_context "dhcp" ["mpl"; "api"; "ether"];
    Pathname.define_context "socket/unix" ["api"];
    Pathname.define_context "http" ["api"; "socket/"^os];

    (* do not compile and pack with the standard lib, and point to right OS module *)
    flag ["ocaml"; "compile"] & S [A"-I"; A (lib "lib"); A"-nostdlib"; A"-I"; A(oslib os)];
    flag ["ocaml"; "pack"   ] & S [A"-I"; A (lib "lib"); A"-nostdlib"];

    (* use pa_lwt syntax extension if needed *)
    flag ["ocaml"; "compile" ; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cmo" (lib "syntax"))];
    flag ["ocaml"; "ocamldep"; "pa_lwt"] & S[A"-pp"; A(sf "camlp4o -I %s pa_lwt.cmo" (lib "syntax"))];

  | _ -> ()
end
