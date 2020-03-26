open Astring
open Mirage_impl_misc
module Key = Mirage_key
module Info = Functoria.Info
module Codegen = Functoria.Codegen
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

let opam_path ~name = Fpath.(v name + "opam")

let opam_name ~name ~target =
  String.concat ~sep:"-" [ "mirage"; "unikernel"; name; target ]

let unikernel_opam_name ~name target =
  let target = Fmt.strf "%a" Key.pp_target target in
  opam_name ~name ~target

let clean_opam ~name target =
  Action.rm (opam_path ~name:(unikernel_opam_name ~name target))

let append fmt s = Fmt.pf fmt (s ^^ "@.")

let configure_makefile ~no_depext ~opam_name =
  let open Codegen in
  Action.with_output ~path:(Fpath.v "Makefile") ~purpose:"Makefile" (fun fmt ->
      append fmt "# %s" (generated_header ());
      append fmt "";
      append fmt "-include Makefile.user";
      append fmt "";
      let depext = if no_depext then "" else "\n\t$(DEPEXT)" in
      append fmt
        "OPAM = opam\n\
         DEPEXT ?= $(OPAM) pin add -k path --no-action --yes %s . &&\\\n\
         \t$(OPAM) depext --yes --update %s ;\\\n\
         \t$(OPAM) pin remove --no-action %s\n\n\
         .PHONY: all depend depends clean build\n\
         all:: build\n\n\
         depend depends::%s\n\
         \t$(OPAM) install -y --deps-only .\n\n\
         build::\n\
         \tmirage build\n\n\
         clean::\n\
         \tmirage clean\n"
        opam_name opam_name opam_name depext)

let configure_opam ~name info =
  Action.with_output ~path:(opam_path ~name) ~purpose:"opam file" (fun fmt ->
      Opam.pp fmt (Info.opam info))

let configure i =
  let name = Info.name i in
  let root = Fpath.to_string (Info.build_dir i) in
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  Log.info (fun m -> m "Configuring for target: %a" Key.pp_target target);
  let opam_name = unikernel_opam_name ~name target in
  let target_debug = Key.(get ctx target_debug) in
  if target_debug && target <> `Hvt then
    Log.warn (fun m -> m "-g not supported for target: %a" Key.pp_target target);
  configure_myocamlbuild () >>= fun () ->
  Action.List.iter ~f:(clean_opam ~name)
    [ `Unix; `MacOSX; `Xen; `Qubes; `Hvt; `Spt; `Virtio; `Muen; `Genode ]
  >>= fun () ->
  configure_opam ~name:opam_name i >>= fun () ->
  let no_depext = Key.(get ctx no_depext) in
  configure_makefile ~no_depext ~opam_name >>= fun () ->
  ( match target with
  | #Mirage_key.mode_solo5 -> generate_manifest_json ()
  | _ -> Action.ok () )
  >>= fun () ->
  match target with
  | `Xen ->
      configure_main_xl ~ext:"xl" i >>= fun () ->
      configure_main_xl ~substitutions:[] ~ext:"xl.in" i >>= fun () ->
      configure_main_xe ~root ~name >>= fun () ->
      Mirage_configure_libvirt.configure_main ~root ~name
  | `Virtio -> Mirage_configure_libvirt.configure_virtio ~root ~name
  | _ -> Action.ok ()
