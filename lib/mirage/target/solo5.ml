open Functoria
open Action.Syntax
open Astring
module Key = Mirage_key
module Log = Mirage_impl_misc.Log

let solo5_manifest_path = Fpath.v "manifest.json"

let flags_generator target = Fmt.str "%a-ldflags.sh" Key.pp_target target

let flags_file target = Fmt.str "%a-ldflags" Key.pp_target target

type solo5_target = [ `Virtio | `Muen | `Hvt | `Genode | `Spt ]

type xen_target = [ `Xen | `Qubes ]

type t = [ solo5_target | xen_target ]

let cast = function #t as t -> t | _ -> invalid_arg "not a solo5 target."

let build_packages =
  [ Functoria.package ~scope:`Switch ~build:true "ocaml-freestanding" ]

let runtime_packages target =
  match target with
  | #solo5_target ->
      [ Functoria.package ~min:"0.7.0" ~max:"0.8.0" "mirage-solo5" ]
  | #xen_target -> [ Functoria.package ~min:"7.0.0" ~max:"8.0.0" "mirage-xen" ]

let packages target = build_packages @ runtime_packages target

let context_name i =
  let target = Info.get i Key.target in
  Fmt.str "mirage-%a" Key.pp_target target

(* OCaml freestanding build context. *)
let build_context ?build_dir:_ i =
  let profile_release = Dune.stanza "(profile release)" in
  let build_context =
    Dune.stanzaf
      {|
  (context (default
  (name %s)
  (host default)
  (toolchain freestanding)
  (disable_dynamically_linked_foreign_archives true)
  ))
  |}
      (context_name i)
  in
  [ profile_release; build_context ]

(* Configure step *)
let generate_manifest_json with_devices () =
  Log.info (fun m -> m "generating manifest");
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
  let s = String.concat ~sep:", " devices in
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
 (link_flags %a -cclib "-z solo5-abi=%a")
 (modules (:standard \ config manifest))
 (foreign_stubs (language c) (names manifest))
)
|}
    (context_name i) main (pp_list "libraries") libraries (pp_list "link_flags")
    flags Key.pp_target target

let subdir name s = Dune.stanzaf "(subdir %s\n %a)\n" name Dune.pp (Dune.v s)

let alias_override i =
  Dune.stanzaf
    {|
  (alias
  (name default)
  (enabled_if (= %%{context_name} "%s"))
  (deps (alias_rec all))
  )
|}
    (context_name i)

let dune i = [ main i; manifest i; rename i; alias_override i ]

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
