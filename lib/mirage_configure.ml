open Rresult
open Astring
open Mirage_impl_misc

module Key = Mirage_key
module Info = Functoria.Info
module Codegen = Functoria_app.Codegen
module CC_to_OPT = Mirage_cc_to_opt

open Mirage_configure_virtio
open Mirage_configure_xen
open Mirage_configure_solo5
open Mirage_configure_unix

let configure_post_build_rules _ ~name ~binary_location ~target =
  match target with
  | #Mirage_key.mode_unix -> configure_unix ~name ~binary_location ~target
  | #Mirage_key.mode_xen -> configure_xen ~name ~binary_location ~target
  | #Mirage_key.mode_solo5 -> configure_solo5 ~name ~binary_location ~target

let myocamlbuild_path = Fpath.(v "myocamlbuild.ml")

(* ocamlbuild will give a misleading hint on build failures
 * ( https://github.com/ocaml/ocamlbuild/blob/0eb62b72b5abd520484210125b18073338a634bc/src/ocaml_compiler.ml#L130 )
 * if it doesn't detect that the project is an ocamlbuild
 * project.  The only facility for hinting this is presence of
 * myocamlbuild.ml or _tags
 * ( https://github.com/ocaml/ocamlbuild/blob/0eb62b72b5abd520484210125b18073338a634bc/src/options.ml#L375-L387 )
 * so we create an empty myocamlbuild.ml . *)
let configure_myocamlbuild () =
  Bos.OS.File.exists myocamlbuild_path >>= function
  | true -> R.ok ()
  | false -> Bos.OS.File.write myocamlbuild_path ""

(* we made it, so we should clean it up *)
let clean_myocamlbuild () =
  match Bos.OS.Path.stat myocamlbuild_path with
  | Ok stat when stat.Unix.st_size = 0 -> Bos.OS.File.delete myocamlbuild_path
  | _ -> R.ok ()

let opam_path ~name = Fpath.(v name + "opam")

let configure_opam ~name info =
  let open Codegen in
  let file = opam_path ~name in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ());
      Info.opam ~name fmt info;
      append fmt "maintainer: \"dummy\"";
      append fmt "authors: \"dummy\"";
      append fmt "homepage: \"dummy\"";
      append fmt "bug-reports: \"dummy\"";
      append fmt "build: [ \"mirage\" \"build\" ]";
      append fmt "synopsis: \"This is a dummy\"";
      R.ok ())
    "opam file"

let opam_name ~name ~target =
  String.concat ~sep:"-" ["mirage"; "unikernel"; name; target]

let unikernel_opam_name ~name target =
  let target = Fmt.strf "%a" Key.pp_target target in
  opam_name ~name ~target

let clean_opam ~name target =
  Bos.OS.File.delete (opam_path ~name:(unikernel_opam_name ~name target))

let configure_makefile ~no_depext ~opam_name =
  let open Codegen in
  let file = Fpath.(v "Makefile") in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt "# %s" (generated_header ());
      newline fmt;
      append fmt "-include Makefile.user";
      newline fmt;
      let depext = if no_depext then "" else "\n\t$(DEPEXT)" in
      append fmt "OPAM = opam\n\
                  DEPEXT ?= $(OPAM) pin add -k path --no-action --yes %s . &&\\\n\
                  \t$(OPAM) depext --yes --update %s ;\\\n\
                  \t$(OPAM) pin remove --no-action %s\n\
                  \n\
                  .PHONY: all depend depends clean build\n\
                  all:: build\n\
                  \n\
                  depend depends::%s\n\
                  \t$(OPAM) install -y --deps-only .\n\
                  \n\
                  build::\n\
                  \tmirage build\n\
                  \n\
                  clean::\n\
                  \tmirage clean\n"
        opam_name opam_name opam_name depext;
      R.ok ())
    "Makefile"

let custom_runtime = function
  | #Mirage_key.mode_xen -> Some "xen"
  | #Mirage_key.mode_unix | #Mirage_key.mode_solo5 -> None

let output_of_target = function
  | #Mirage_key.mode_unix -> "main.exe"
  | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 -> "main.exe.o"

let variant_of_target = function
  | #Mirage_key.mode_solo5 -> "freestanding"
  | #Mirage_key.mode_xen -> "xen"
  | #Mirage_key.mode_unix -> "unix"

let exclude_modules_of_target = function
  | #Mirage_key.mode_solo5 -> [ "config"; "manifest" ]
  | #Mirage_key.mode_xen | #Mirage_key.mode_unix -> [ "config" ]

let dune_path = Fpath.v "dune.build"
let dune_project_path = Fpath.v "dune-project"
let dune_workspace_path = Fpath.v "dune-workspace"

let configure_dune i =
  let ctx = Info.context i in
  let warn_error = Key.(get ctx warn_error) in
  let target = Key.(get ctx target) in
  let custom_runtime = custom_runtime target in
  let libs = Info.libraries i in
  let name = Info.name i in
  let binary_location = output_of_target target in
  let cflags =
    [ "-g"; "-w"; "+A-4-41-42-44"; "-bin-annot"; "-strict-sequence";
      "-principal"; "-safe-string" ]
    @ (if warn_error then [ "-warn-error"; "+1..49" ] else [])
    @ (match target with #Mirage_key.mode_unix -> [ "-thread" ] | _ -> [])
    @ (if terminal () then [ "-color"; "always" ] else [])
    @ (match custom_runtime with Some runtime -> [ "-runtime-variant"; runtime ] | _ -> []) in
  ( match target with
    | #Mirage_key.mode_solo5 ->
      extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
      static_libs "mirage-solo5" >>= fun static_libs -> Ok (c_artifacts, static_libs)
    | #Mirage_key.mode_xen ->
      extra_c_artifacts "xen" libs >>= fun c_artifacts ->
      static_libs "mirage-xen" >>= fun static_libs -> Ok (c_artifacts, static_libs)
    | #Mirage_key.mode_unix -> Ok ([], []) ) >>= fun (c_artifacts, static_libs) ->
  CC_to_OPT.run (Array.of_list (c_artifacts @ static_libs)) >>= fun lflags ->
  let s_output_mode = match target with
    | #Mirage_key.mode_unix -> "(native exe)"
    | #Mirage_key.mode_solo5 | #Mirage_key.mode_xen -> "(native object)" in
  let s_libraries = String.concat ~sep:" " libs in
  let s_lflags = String.concat ~sep:" " lflags in
  let s_cflags = String.concat ~sep:" " cflags in
  let s_variants = variant_of_target target in
  let s_forbidden = match target with
    | #Mirage_key.mode_xen | #Mirage_key.mode_solo5 -> "(forbidden_libraries unix)"
    | #Mirage_key.mode_unix -> "" in
  let s_exclude_modules = String.concat ~sep:" " (exclude_modules_of_target target) in
  let res =
    Fmt.strf
{sexp|
  (executable
    (name main)
    (modes %s)
    (libraries %s)
    (link_flags %s)
    (modules (:standard \ %s))
    (flags %s)
    %s
    (variants %s))
  |sexp}
        s_output_mode
        s_libraries
        s_lflags
        s_exclude_modules
        s_cflags
        s_forbidden
        s_variants in
  configure_post_build_rules i ~name ~binary_location ~target >>= fun rules ->
  let res = res ^ "\n" in
  let rules = List.map (fun x -> Sexplib.Sexp.to_string_hum x ^ "\n") rules in
  Bos.OS.File.write_lines dune_path (res :: rules)

let configure_dune_workspace i =
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  let lang = sexp_of_fmt {sexp|(lang dune 2.0)|sexp}
  and variant_feature = sexp_of_fmt {sexp|(using library_variants 0.2)|sexp}
  and implicit_transitive_deps = sexp_of_fmt {sexp|(implicit_transitive_deps true)|sexp}
  and profile_release = sexp_of_fmt {sexp|(profile release)|sexp}
  and base_context = sexp_of_fmt {sexp|(context (default))|sexp} in
  let extra_contexts = match target with
    | #Mirage_key.mode_solo5 | #Mirage_key.mode_xen ->
      [ sexp_of_fmt {sexp|
          (context (default
            (name mirage-%s)
            (host default)
            (env (_ (c_flags (:include cflags.sexp))))))
          |sexp} (variant_of_target target) ]
    | #Mirage_key.mode_unix -> [] in
  let rules = lang :: profile_release :: base_context :: extra_contexts in
  Bos.OS.File.write_lines
    dune_workspace_path
    (List.map (fun x -> Sexplib.Sexp.to_string_hum x ^ "\n") rules) >>= fun () ->
  let rules = [ lang; variant_feature; implicit_transitive_deps; ] in
  Bos.OS.File.write_lines
    dune_project_path
    (List.map (fun x -> Sexplib.Sexp.to_string_hum x ^ "\n") rules)

let clean_dune () = Bos.OS.File.delete dune_path
let clean_dune_project () = Bos.OS.File.delete dune_project_path
let clean_dune_workspace () = Bos.OS.File.delete dune_workspace_path

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
  configure_dune i >>= fun () ->
  rr_iter (clean_opam ~name)
    [`Unix; `MacOSX; `Xen; `Qubes; `Hvt; `Spt; `Virtio; `Muen; `Genode]
  >>= fun () ->
  configure_dune_workspace i >>= fun () ->
  configure_opam ~name:opam_name i >>= fun () ->
  let no_depext = Key.(get ctx no_depext) in
  configure_makefile ~no_depext ~opam_name >>= fun () ->
  (match target with
    | #Mirage_key.mode_solo5 -> generate_manifest_json ()
    | _ -> R.ok ()) >>= fun () ->
  match target with
  | `Xen ->
    configure_main_xl ~ext:"xl" i >>= fun () ->
    configure_main_xl ~substitutions:[] ~ext:"xl.in" i >>= fun () ->
    configure_main_xe ~root ~name >>= fun () ->
    configure_main_libvirt_xml ~root ~name
  | `Virtio ->
    configure_virtio_libvirt_xml ~root ~name
  | _ -> R.ok ()
