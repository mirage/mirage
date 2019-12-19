open Rresult
open Astring
open Mirage_impl_misc

module Info = Functoria.Info
module Codegen = Functoria_app.Codegen
module Log = Mirage_impl_misc.Log
module Key = Mirage_key

let solo5_manifest_path = Fpath.v "manifest.json"

let clean_manifest () =
  Bos.OS.File.delete solo5_manifest_path >>= fun () ->
  Bos.OS.File.delete (Fpath.v "manifest.ml")

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

let solo5_pkg = function
  | `Virtio -> "solo5-bindings-virtio", ".virtio"
  | `Muen -> "solo5-bindings-muen", ".muen"
  | `Hvt -> "solo5-bindings-hvt", ".hvt"
  | `Genode -> "solo5-bindings-genode", ".genode"
  | `Spt -> "solo5-bindings-spt", ".spt"
  | _ ->
    invalid_arg "solo5 bindings only defined for solo5 targets"

(* Generate configure part of Solo5 target. *)

let configure_solo5 ~name ~binary_location ~target =
  generate_manifest_json () >>= fun () ->

  let _, post = solo5_pkg target in
  let out = name ^ post in
  let alias =
    Fmt.strf
{sexp|
(alias
  (name %a)
   (enabled_if (= %%{context_name} "mirage-freestanding"))
   (deps libmirage-solo5_bindings.a %s))
|sexp}
      Key.pp_target target out in
  let rule_unikernel =
    Fmt.strf
{sexp|
(rule
  (targets %s)
  (mode promote)
  (deps %s manifest.o)
  (action (run ld libmirage-solo5_bindings.a %%{read-lines:ldflags} manifest.o %s -o %s)))
|sexp}
      out binary_location binary_location out in
  let rule_libmirage_solo5_bindings =
    Fmt.strf
      {sexp|(rule (copy %%{lib:mirage-solo5:libmirage-solo5_bindings.a} libmirage-solo5_bindings.a))|sexp} in
  let rule_libs =
    Fmt.strf
      {sexp|(rule (copy %%{lib:ocaml-freestanding:libs.sexp} libs.sexp))|sexp} in
  let rule_ldflags =
    Fmt.strf
      {sexp|(rule (copy %%{lib:ocaml-freestanding:ldflags} ldflags))|sexp} in
  let rule_cflags =
    Fmt.strf
      {sexp|(rule (copy %%{lib:ocaml-freestanding:cflags.sexp} cflags.sexp))|sexp} in
  let rule_manifest_c =
    Fmt.strf
{sexp|
(rule
  (targets manifest.c)
  (deps manifest.json)
  (action (run solo5-elftool gen-manifest manifest.json manifest.c)))
|sexp} in
  let rule_manifest_o =
    Fmt.strf
{sexp|
(library
  (name manifest)
  (modules manifest)
  (foreign_stubs (language c) (names manifest)
    (flags (:include cflags.sexp))))
|sexp} in
  Bos.OS.File.write (Fpath.v "manifest.ml") "" >>= fun () ->
  Ok ( rule_libmirage_solo5_bindings
       :: rule_ldflags :: rule_cflags :: rule_libs
       :: rule_manifest_c :: rule_manifest_o
       :: alias :: rule_unikernel :: [] )
