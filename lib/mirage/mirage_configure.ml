open Mirage_impl_misc
module Key = Mirage_key
module Info = Functoria.Info
module Opam = Functoria.Opam
module Action = Functoria.Action
open Mirage_configure_xen
open Mirage_configure_solo5
open Action.Infix

let myocamlbuild_path = Fpath.(v "myocamlbuild.ml")

(* ocamlbuild will give a misleading hint on build failures
 * ( https://github.com/ocaml/ocamlbuild/blob/0eb62b72b5abd520484210125b18073338a634bc/src/ocaml_compiler.ml#L130 )
 * if it doesn't detect that the project is an ocamlbuild
 * project.  The only facility for hinting this is presence of
 * myocamlbuild.ml or _tags
 * ( https://github.com/ocaml/ocamlbuild/blob/0eb62b72b5abd520484210125b18073338a634bc/src/options.ml#L375-L387 )
 * so we create an empty myocamlbuild.ml . *)
let configure_myocamlbuild () =
  Action.is_file myocamlbuild_path >>= function
  | true -> Action.ok ()
  | false -> Action.write_file myocamlbuild_path ""

(* we made it, so we should clean it up *)
let clean_myocamlbuild () =
  Action.size_of myocamlbuild_path >>= function
  | Some 0 -> Action.rm myocamlbuild_path
  | _ -> Action.ok ()

let configure i =
  let name = Info.name i in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  Log.info (fun m -> m "Configuring for target: %a" Key.pp_target target);
  let target_debug = Key.(get ctx target_debug) in
  if target_debug && target <> `Hvt then
    Log.warn (fun m -> m "-g not supported for target: %a" Key.pp_target target);
  configure_myocamlbuild () >>= fun () ->
  ( match target with
  | #Mirage_key.mode_solo5 -> generate_manifest_json true ()
  (* On Xen, a Solo5 manifest must be present to keep the build system and
     Solo5 happy, but we intentionally do not generate any devices[] as
     their naming does not follow the Solo5 rules. *)
  | #Mirage_key.mode_xen -> generate_manifest_json false ()
  | _ -> Action.ok () )
  >>= fun () ->
  match target with
  | `Xen ->
      configure_main_xl ~ext:"xl" i >>= fun () ->
      configure_main_xl ~substitutions:[] ~ext:"xl.in" i >>= fun () ->
      Mirage_configure_libvirt.configure_main ~name
  | `Virtio -> Mirage_configure_libvirt.configure_virtio ~name
  | _ -> Action.ok ()

let files i =
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  Fpath.v "myocamlbuild.ml"
  ::
  ( match target with
  | `Virtio -> Mirage_configure_solo5.files i
  | #Mirage_key.mode_solo5 -> Mirage_configure_solo5.files i
  | `Xen -> Mirage_configure_xen.files i
  | _ -> [] )
