open Functoria
open Action.Syntax
module Key = Mirage_key

let solo5_manifest_path = Fpath.v "manifest.json"

type solo5_target = [ `Virtio | `Muen | `Hvt | `Genode | `Spt ]
type xen_target = [ `Xen | `Qubes ]
type t = [ solo5_target | xen_target ]

let cast = function #t as t -> t | _ -> invalid_arg "not a solo5 target."

let build_packages =
  [
    Functoria.package ~min:"0.8.1" ~max:"0.9.0" ~scope:`Switch ~build:true
      "ocaml-solo5";
    Functoria.package ~min:"0.7.5" ~max:"0.9.0" ~scope:`Switch ~build:true
      "solo5";
  ]

let runtime_packages target =
  match target with
  | #solo5_target ->
      [ Functoria.package ~min:"0.9.0" ~max:"0.10.0" "mirage-solo5" ]
  | #xen_target -> [ Functoria.package ~min:"8.0.0" ~max:"9.0.0" "mirage-xen" ]

let packages target = build_packages @ runtime_packages target
let context_name _i = "solo5"

(* OCaml solo5 build context. *)
let build_context ?build_dir:_ i =
  let build_context =
    Dune.stanzaf
      {|
  (context (default
  (name %s)
  (host default)
  (toolchain solo5)
  (merlin)
  (disable_dynamically_linked_foreign_archives true)
  ))
  |}
      (context_name i)
  in
  [ build_context ]

(* Configure step *)
let generate_manifest_json with_devices () =
  let networks =
    List.map (fun n -> (n, `Network)) !Mirage_impl_network.all_networks
  in
  let blocks =
    Hashtbl.fold
      (fun k _v acc -> (k, `Block) :: acc)
      Mirage_impl_block.all_blocks []
  in
  let to_string (name, typ) =
    Fmt.str {json|{ "name": %S, "type": %S }|json} name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC")
  in
  let devices =
    if with_devices then List.map to_string (networks @ blocks) else []
  in
  let s = String.concat ", " devices in
  let* () =
    Action.with_output ~path:solo5_manifest_path
      ~purpose:"Solo5 application manifest file" (fun fmt ->
        Fmt.pf fmt
          {|{
  "type": "solo5.manifest",
  "version": 1,
  "devices": [ %s ]
}
|}
          s)
  in
  Action.write_file (Fpath.v "manifest.ml") ""

let configure i =
  let name = Info.name i in
  let target = Info.get i Key.target in
  let* () =
    match target with
    | #solo5_target -> generate_manifest_json true ()
    | #xen_target -> generate_manifest_json false ()
    | _ -> assert false
  in
  match target with
  | `Xen ->
      let* () = Xen.configure_main_xl ~ext:"xl" i in
      let* () = Xen.configure_main_xl ~substitutions:[] ~ext:"xl.in" i in
      Libvirt.configure_main ~name
  | `Virtio -> Libvirt.configure_virtio ~name
  | _ -> Action.ok ()

(* Build *)

let ext = function
  | `Virtio -> ".virtio"
  | `Muen -> ".muen"
  | `Hvt -> ".hvt"
  | `Genode -> ".genode"
  | `Spt -> ".spt"
  | `Xen | `Qubes -> ".xen"
  | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

let main i = Fpath.(base (rem_ext (Info.main i)))

let out i =
  let target = Info.get i Key.target in
  let public_name =
    match Info.output i with None -> Info.name i | Some o -> o
  in
  public_name ^ ext target

let rename i =
  let out = out i in
  let main = Fpath.to_string (main i) in
  Dune.stanzaf
    {|
(rule
 (target %s)
 (enabled_if (= %%{context_name} "%s"))
 (deps %s.exe)
 (action
  (copy %s.exe %%{target})))
|}
    out (context_name i) main main

let manifest _i =
  Dune.stanzaf
    {|
(rule
 (targets manifest.c)
 (deps manifest.json)
 (action
  (run solo5-elftool gen-manifest manifest.json manifest.c)))
|}

let solo5_abi = function
  | #Key.mode_unix -> assert false
  | #Key.mode_xen -> "xen"
  | `Virtio -> "virtio"
  | `Hvt -> "hvt"
  | `Muen -> "muen"
  | `Genode -> "genode"
  | `Spt -> "spt"

let main i =
  let libraries = Info.libraries i in
  let flags = Mirage_dune.flags i in
  let main = Fpath.to_string (main i) in
  let target = Info.get i Key.target in
  let pp_list f = Dune.compact_list f in
  Dune.stanzaf
    {|
(executable
 (enabled_if (= %%{context_name} "%s"))
 (name %s)
 (modes (native exe))
 (libraries %a)
 (link_flags %a -cclib "-z solo5-abi=%s")
 (modules (:standard \ %a manifest))
 (foreign_stubs (language c) (names manifest))
)
|}
    (context_name i) main (pp_list "libraries") libraries (pp_list "link_flags")
    flags (solo5_abi target) Fpath.pp
    (Fpath.rem_ext (Fpath.base (Info.config_file i)))

let subdir name s = Dune.stanzaf "(subdir %s\n %a)\n" name Dune.pp (Dune.v s)
let dune i = [ main i; manifest i; rename i ]

let install i =
  let target = Info.get i Key.target in
  let name = Info.name i in
  let out = out i in
  let open Fpath in
  let additional_artifacts =
    match target with
    | `Xen -> [ v (name ^ ".xl"); v (name ^ ".xl.in") ]
    | _ -> []
  in
  Install.v ~bin:[ (v out, v out) ] ~etc:additional_artifacts ()
