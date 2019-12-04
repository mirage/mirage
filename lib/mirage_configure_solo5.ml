open Rresult
open Astring
open Mirage_impl_misc

module Info = Functoria.Info
module Codegen = Functoria_app.Codegen
module Log = Mirage_impl_misc.Log
module Key = Mirage_key

let solo5_manifest_path = Fpath.v "manifest.json"

let clean_manifest () =
  Bos.OS.File.delete solo5_manifest_path

let generate_manifest_json () =
  Log.info (fun m -> m "generating manifest");
  let networks = List.map (fun n -> (n, `Network))
    !Mirage_impl_network.all_networks in
  let blocks = Hashtbl.fold (fun k _v acc -> (k, `Block) :: acc)
      Mirage_impl_block.all_blocks [] in
  let to_string (name, typ) =
    Fmt.strf {json|{ "name": %S, "type": %S }|json}
      name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC") in
  let devices = List.map to_string (networks @ blocks) in
  let s = String.concat ~sep:", " devices in
  let open Codegen in
  let file = solo5_manifest_path in
  with_output file (fun oc () ->
      let fmt = Format.formatter_of_out_channel oc in
      append fmt
{json|{
  "type": "solo5.manifest",
  "version": 1,
  "devices": [ %s ]
}
|json} s;
      R.ok ())
    "Solo5 application manifest file"

let generate_manifest_c () =
  let json = solo5_manifest_path in
  let c = "_build/manifest.c" in
  let cmd = Bos.Cmd.(v "solo5-elftool" % "gen-manifest" % Fpath.to_string json % c)
  in
  Bos.OS.Dir.create Fpath.(v "_build") >>= fun _created ->
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd

let solo5_pkg = function
  | `Virtio -> "solo5-bindings-virtio", ".virtio"
  | `Muen -> "solo5-bindings-muen", ".muen"
  | `Hvt -> "solo5-bindings-hvt", ".hvt"
  | `Genode -> "solo5-bindings-genode", ".genode"
  | `Spt -> "solo5-bindings-spt", ".spt"
  | _ ->
    invalid_arg "solo5 bindings only defined for solo5 targets"

let cflags pkg = pkg_config pkg ["--cflags"]

let compile_manifest target =
  let pkg, _post = solo5_pkg target in
  let c = "_build/manifest.c" in
  let obj = "_build/manifest.o" in
  cflags pkg >>= fun cflags ->
  let cmd = Bos.Cmd.(v "cc" %% of_list cflags % "-c" % c % "-o" % obj)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd

(* Process to get & save into files flags. *)

open Sexplib

let cflags_sexp_path = Fpath.((v ".mirage" + "solo5") / "cflags.sexp")
let lflags_path = Fpath.((v ".mirage" + "solo5") / "lflags")
let libs_sexp_path = Fpath.((v ".mirage" + "solo5") / "libs.sexp")
let libdir_path = Fpath.((v ".mirage" + "solo5") / "libdir")

let cflags ~target =
  let pkg, _ = solo5_pkg target in
  pkg_config pkg [ "--cflags" ] >>= fun cflags ->
  let sexp =
    sexp_of_fmt
      {sexp|(%a)|sexp}
      Fmt.(list ~sep:(always " ") string) cflags in
  Bos.OS.File.write_lines
    cflags_sexp_path
    (List.map (fun x -> Sexp.to_string_hum x ^ "\n") [ sexp ])

let lflags ~target =
  let pkg, _ = solo5_pkg target in
  pkg_config pkg [ "--variable=ldflags" ] >>= fun lflags ->
  Bos.OS.File.write_lines
    lflags_path lflags

let libs ~target =
  let pkg, _ = solo5_pkg target in
  pkg_config pkg [ "--libs" ] >>= fun libs ->
  let sexp =
    sexp_of_fmt
      {sexp|(%a)|sexp}
      Fmt.(list ~sep:(always " ") string) libs in
  Bos.OS.File.write_lines
    libs_sexp_path
    (List.map (fun x -> Sexp.to_string_hum x ^ "\n") [ sexp ])

let libdir ~target =
  let pkg, _ = solo5_pkg target in
  pkg_config pkg [ "--variable=libdir" ] >>= fun libdir ->
  Bos.OS.File.write_lines
    libdir_path libdir

(* Generate configure part of Solo5 target. *)

let hijack_dune () =
  let lines =
    [ "(include dune.config)"
    ; "(dirs .mirage.solo5)"
    ; "(include dune.build)" ] in
  Bos.OS.File.write_lines (Fpath.v "dune") lines

let configure_solo5 ~name ~binary_location ~target =
  hijack_dune () >>= fun () ->
  Bos.OS.Dir.create ~path:true Fpath.(v ".mirage" + "solo5") >>= fun _ ->
  cflags ~target >>= fun () ->
  lflags ~target >>= fun () ->
  libs ~target >>= fun () ->
  libdir ~target >>= fun () ->
  generate_manifest_json () >>= fun () ->

  let _, post = solo5_pkg target in
  let out = name ^ post in
  let alias =
    sexp_of_fmt
      {sexp|
      (alias
        (name %a)
         (enabled_if (= %%{context_name} "mirage-freestanding"))
         (deps %s))
      |sexp} Key.pp_target target out in
  let rule_unikernel =
    sexp_of_fmt
      {sexp|
      (rule
        (targets %s)
        (mode promote)
        (deps %s manifest.o)
        (action (run ld %%{read-lines:lflags} manifest.o %s -o %s)))
      |sexp} out binary_location binary_location out in
  let rule_libs =
    sexp_of_fmt
      {sexp|(rule (copy %a libs.sexp))|sexp}
      Fpath.pp libs_sexp_path in
  let rule_lflags =
    sexp_of_fmt
      {sexp|(rule (copy %a lflags))|sexp}
      Fpath.pp lflags_path in
  let rule_cflags =
    sexp_of_fmt
      {sexp|(rule (copy %a cflags.sexp))|sexp}
      Fpath.pp cflags_sexp_path in
  let rule_libdir =
    sexp_of_fmt
      {sexp|(rule (copy %a libdir))|sexp}
      Fpath.pp libdir_path in
  let rule_manifest_c =
    sexp_of_fmt
      {sexp|
      (rule
        (targets manifest.c)
        (deps manifest.json)
        (action (run solo5-elftool gen-manifest manifest.json manifest.c)))
      |sexp} in
  let rule_manifest_o =
    sexp_of_fmt
      {sexp|
      (library
        (name manifest)
        (modules manifest)
        (foreign_stubs (language c) (names manifest)
          (flags (:include cflags.sexp))))
      |sexp} in
  Bos.OS.File.write (Fpath.v "manifest.ml") "" >>= fun () ->
  Ok ( rule_lflags :: rule_cflags :: rule_libs :: rule_libdir
       :: rule_manifest_c :: rule_manifest_o
       :: alias :: rule_unikernel :: [] )
