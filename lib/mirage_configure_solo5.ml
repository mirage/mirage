open Rresult
open Astring
open Mirage_impl_misc

module Codegen = Functoria_app.Codegen
module Log = Mirage_impl_misc.Log

let solo5_manifest_path = Fpath.v "_build/manifest.json"

let clean_manifest () =
  Bos.OS.File.delete solo5_manifest_path

let generate_manifest_json with_devices () =
  Log.info (fun m -> m "generating manifest");
  let networks = List.map (fun n -> (n, `Network))
    !Mirage_impl_network.all_networks in
  let blocks = Hashtbl.fold (fun k _v acc -> (k, `Block) :: acc)
      Mirage_impl_block.all_blocks [] in
  let to_string (name, typ) =
    Fmt.strf {json|{ "name": %S, "type": %S }|json}
      name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC") in
  let devices = if with_devices then
    (List.map to_string (networks @ blocks))
  else [] in
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

let bin_extension = function
  | `Virtio -> ".virtio"
  | `Muen -> ".muen"
  | `Hvt -> ".hvt"
  | `Genode -> ".genode"
  | `Spt -> ".spt"
  | `Xen | `Qubes -> ".xen"
  | _ ->
    invalid_arg "extension only defined for solo5 targets"

let solo5_bindings_pkg = function
  | `Virtio -> "solo5-bindings-virtio"
  | `Muen -> "solo5-bindings-muen"
  | `Hvt -> "solo5-bindings-hvt"
  | `Genode -> "solo5-bindings-genode"
  | `Spt -> "solo5-bindings-spt"
  | `Xen | `Qubes -> "solo5-bindings-xen"
  | _ ->
    invalid_arg "solo5 bindings package only defined for solo5 targets"

let solo5_platform_pkg = function
  | #Mirage_key.mode_solo5 -> "mirage-solo5"
  | #Mirage_key.mode_xen -> "mirage-xen"
  | _ ->
    invalid_arg "solo5 platform package only defined for solo5 targets"

let cflags pkg = pkg_config pkg ["--cflags"]

let compile_manifest target =
  let bindings = solo5_bindings_pkg target in
  let c = "_build/manifest.c" in
  let obj = "_build/manifest.o" in
  cflags bindings >>= fun cflags ->
  let cmd = Bos.Cmd.(v "cc" %% of_list cflags % "-c" % c % "-o" % obj)
  in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Bos.OS.Cmd.run cmd
