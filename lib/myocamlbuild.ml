open Ocamlbuild_plugin
open Command
open Ocamlbuild_pack.Ocaml_compiler
open Ocamlbuild_pack.Ocaml_utils
open Ocamlbuild_pack.Tools

let ps = Printf.sprintf
let ep = Printf.eprintf

(* This decides the global OS backend. It could be moved into explicit
   dependencies in the future, but for now is set as an environment
   variable *)
let os =
  let os = getenv "MIRAGEOS" ~default:"unix" in
  if os <> "unix" && os <> "xen" && os <> "node" then
    (ep "`%s` is not a supported OS\n" os; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "OS: %s" os; os)

(* This decides which Net module to use (direct or socket) *)
let flow = 
  let flow = getenv "MIRAGEFLOW" ~default:"direct" in
  if flow <> "direct" && flow <> "socket" then
    (ep "`%s` is not a supported Flow type\n" flow; exit (-1))
  else
    (Ocamlbuild_pack.Log.dprintf 0 "Flow: %s" flow; flow)

let _ =
  let subdir = match os,flow with
  |"unix","socket" -> "unix-socket"
  |"unix","direct" -> "unix-direct"
  |"xen" ,"direct" -> "xen-direct"
  |"node","socket" -> "node-socket"
  |_ -> ep "%s-%s is not a supported kernel combination\n" os flow; exit (-1) in
  Options.build_dir := "_build/" ^ subdir

(* Utility functions (e.g. to execute a command and return lines read) *)
module Util = struct
  let split s ch =
    let x = ref [] in
    let rec go s =
      let pos = String.index s ch in
      x := (String.before s pos)::!x;
      go (String.after s (pos + 1))
    in
    try
      go s
    with Not_found -> !x

    let split_nl s = split s '\n'

    let run_and_read x = List.hd (split_nl (Ocamlbuild_pack.My_unix.run_and_read x))
end

(* OS detection *)
module OS = struct

  type u = Linux | Darwin
  type t = Unix of u | Xen | Node
  let host = match String.lowercase (Util.run_and_read "uname -s") with
    | "linux"  -> Unix Linux
    | "darwin" -> Unix Darwin
    | os -> Printf.eprintf "`%s` is not a supported host OS\n" os; exit (-1)
  let target = match String.lowercase os with
    | "unix" -> host (* Map the target to the current host, as cross-compiling is no use *)
    | "xen"  -> Xen
    | "node" -> Node
    | x -> failwith ("unknown target os: " ^ x)
end

(* Rules for MPL compiler *)
module MPL = struct

  let mplc_bin = "mplc" 

  let mpl_c tags arg out =
    Cmd (S [A mplc_bin; A"-q"; T(tags++"mpl"); P arg; Sh">"; Px out])

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

let libexts = (match OS.target with |OS.Node ->  "cmo" |OS.Xen |OS.Unix _ -> "cmx") :: ["cmi";"a";"o"]
let libbits dir name = List.map (fun e -> dir / name ^ "." ^ e) libexts

(* Compile the right OS module *)
let () = rule
  ~prods:(libbits "std/lib" "oS")
  ~deps:(libbits ("os" / os) "oS")
   "OS link"
   (fun env builder ->
     Seq (List.map (fun f -> cp ("os" / os / "oS." ^ f) ("std/lib" / "oS." ^ f)) libexts)
   )

(* Compile the right Net module *)
let () = rule
  ~prods:(libbits "std/lib" "net")
  ~deps:(libbits ("net" / flow) "net")
   "Net link"
   (fun env builder ->
     Seq (List.map (fun f -> cp ("net" / flow / "net." ^ f) ("std/lib" / "net." ^ f)) libexts)
   )

let camlp4_pp mode =
  let camlp4_dir = P (Lazy.force stdlib_dir ^ "/camlp4") in
  let exp =
    match mode with
    |`orig -> A "Camlp4OCamlOriginalQuotationExpander"
    |`rev -> A "Camlp4OCamlRevisedQuotationExpander" in
  S [ A"-pp"; Quote (S [A"camlp4"; A"-I"; camlp4_dir;
      A"-parser"; A"o"; A"-parser"; A"op"; A"-printer"; A"p";
      A"-parser"; A"Camlp4GrammarParser"; A"-parser"; A"Camlp4QuotationCommon";
      A"-parser"; exp ]); A"-I"; camlp4_dir ]

let _ = dispatch begin function
  | After_rules ->
     (* do not compile and pack with the standard lib *)
     flag ["ocaml"; "compile"; "mirage" ] & S [A"-nostdlib"];
     flag ["ocaml"; "pack"; "mirage"] & S [A"-nostdlib"];

     dep ["pa_lwt"] ["std/syntax/pa_lwt.cma"];

     flag ["ocaml"; "ocamldep"; "camlp4o_syntax"] & camlp4_pp `orig;
     flag ["ocaml"; "compile"; "camlp4o_syntax"] & camlp4_pp `orig;
     flag ["ocaml"; "ocamldep"; "camlp4_syntax"] & camlp4_pp `rev; 
     flag ["ocaml"; "compile"; "camlp4_syntax"] & camlp4_pp `rev; 

     (* use pa_`lib` syntax extension if the _tags file specifies it *)
     List.iter (fun lib ->
      flag ["ocaml"; "compile" ; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s pa_%s.cma" "std/syntax" lib)];
      flag ["ocaml"; "ocamldep"; "pa_" ^ lib] & S[A"-pp"; A (ps "camlp4o -I %s pa_%s.cma" "std/syntax" lib)];
     ) [ "lwt"; "ulex" ];

     (* add a dependency to the local pervasives, only used in stdlib compile *)
     dep ["ocaml"; "compile"; "need_pervasives"] ["std/lib/pervasives.cmi"];

     (* For re-packing libraries (ocamlbuild doesnt pick up for-pack in a pack target) *)
     pflag ["ocaml"; "pack"] "for-repack" (fun param -> S [A "-for-pack"; A param]);

     (* net/direct includes *)
     Pathname.define_context "net/direct/mpl/protocols" ["mpl"];
     Pathname.define_context "net/direct/tcp" ["net/direct/mpl"; "net/direct"];
     Pathname.define_context "net/direct" ["net/direct/mpl"; "net/direct/tcp"; "net/direct/dhcp"];
     Pathname.define_context "net/direct/dhcp" ["net/direct/mpl"; "net/direct" ];

     ()
  | _ -> ()
end
