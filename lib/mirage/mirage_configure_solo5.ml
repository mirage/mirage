open Astring
open Functoria
open Mirage_impl_misc
open Action.Infix
module Log = Mirage_impl_misc.Log
module Key = Mirage_key

let solo5_manifest_path = Fpath.v "_build/manifest.json"

let clean_manifest () = Action.rm solo5_manifest_path

let generate_manifest_json () =
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
    Fmt.strf {json|{ "name": %S, "type": %S }|json} name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC")
  in
  let devices = List.map to_string (networks @ blocks) in
  let pci_devs =
    List.map
      (fun (di, name) ->
        Fmt.strf
{|{
      "name": %S,
      "type": "PCI_BASIC",
      "bus_master_enable": %b,
      "map_bar0": %b,
      "map_bar1": %b,
      "map_bar2": %b,
      "map_bar3": %b,
      "map_bar4": %b,
      "map_bar5": %b,
      "class": %d,
      "subclass": %d,
      "progif": %d,
      "vendor": %d,
      "device_id": %d
    }|}
          name
          di.Mirage_impl_pci.bus_master_enable
          di.Mirage_impl_pci.map_bar0
          di.Mirage_impl_pci.map_bar1
          di.Mirage_impl_pci.map_bar2
          di.Mirage_impl_pci.map_bar3
          di.Mirage_impl_pci.map_bar4
          di.Mirage_impl_pci.map_bar5
          di.Mirage_impl_pci.class_code
          di.Mirage_impl_pci.subclass_code
          di.Mirage_impl_pci.progif
          di.Mirage_impl_pci.vendor_id
          di.Mirage_impl_pci.device_id)
      !Mirage_impl_pci.all_pci_devices in
  let s = String.concat ~sep:",\n    " (devices @ pci_devs) in
  let dma_size =
    List.fold_left
      (fun acc ({ Mirage_impl_pci.dma_size; _ }, _) -> acc + dma_size)
      0
      !Mirage_impl_pci.all_pci_devices in
  Action.with_output ~path:solo5_manifest_path
    ~purpose:"Solo5 application manifest file" (fun fmt ->
      Fmt.pf fmt
        {|{
  "type": "solo5.manifest",
  "version": 1,
  "dma_size": %d,
  "devices": [ %s ]
}
|}
        dma_size s)

let generate_manifest_c () =
  let json = solo5_manifest_path in
  let c = "_build/manifest.c" in
  let cmd =
    Bos.Cmd.(v "solo5-elftool" % "gen-manifest" % Fpath.to_string json % c)
  in
  Action.mkdir Fpath.(v "_build") >>= fun _created ->
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Action.run_cmd cmd

let solo5_pkg = function
  | `Virtio -> ("solo5-bindings-virtio", ".virtio")
  | `Muen -> ("solo5-bindings-muen", ".muen")
  | `Hvt -> ("solo5-bindings-hvt", ".hvt")
  | `Genode -> ("solo5-bindings-genode", ".genode")
  | `Spt -> ("solo5-bindings-spt", ".spt")
  | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

let cflags pkg = pkg_config pkg [ "--cflags" ]

let compile_manifest target =
  let pkg, _post = solo5_pkg target in
  let c = "_build/manifest.c" in
  let obj = "_build/manifest.o" in
  cflags pkg >>= fun cflags ->
  let cmd = Bos.Cmd.(v "cc" %% of_list cflags % "-c" % c % "-o" % obj) in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Action.run_cmd cmd

let files i =
  let ctx = Info.context i in
  let target = Key.(get ctx target) in
  Fpath.v "_build/manifest.json"
  :: (match target with `Virtio -> [ Fpath.v "libvirt.xml" ] | _ -> [])
