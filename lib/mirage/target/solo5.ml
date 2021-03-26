open Astring
open Functoria
open Action.Infix
open Mirage_impl_misc
module Key = Mirage_key

type solo5_target = [ `Virtio | `Muen | `Hvt | `Genode | `Spt ]

type xen_target = [ `Xen | `Qubes ]

type t = [ solo5_target | xen_target ]

let cast = function #t as t -> t | _ -> invalid_arg "not a solo5 target."

let bin_extension = function
  | `Virtio -> ".virtio"
  | `Muen -> ".muen"
  | `Hvt -> ".hvt"
  | `Genode -> ".genode"
  | `Spt -> ".spt"
  | `Xen | `Qubes -> ".xen"

let solo5_bindings_pkg = function
  | `Virtio -> "solo5-bindings-virtio"
  | `Muen -> "solo5-bindings-muen"
  | `Hvt -> "solo5-bindings-hvt"
  | `Genode -> "solo5-bindings-genode"
  | `Spt -> "solo5-bindings-spt"
  | `Xen | `Qubes -> "solo5-bindings-xen"

let solo5_platform_pkg = function
  | #solo5_target -> "mirage-solo5"
  | #xen_target -> "mirage-xen"

let packages = function
  | #xen_target ->
      (* The Mirage/Xen PVH platform package has different version numbers
         than Mirage/Solo5, so needs its own case here. *)
      [
        package ~min:"0.6.0" ~max:"0.7.0" ~libs:[] "solo5-bindings-xen";
        package ~min:"6.0.0" ~max:"7.0.0" "mirage-xen";
      ]
  | #solo5_target as tgt ->
      [
        package ~min:"0.6.0" ~max:"0.7.0" ~libs:[] (solo5_bindings_pkg tgt);
        package ~min:"0.6.1" ~max:"0.7.0" "mirage-solo5";
      ]

(** CONFIGURE **)

let solo5_manifest_path = Fpath.v "_build/manifest.json"

let clean_manifest () = Action.rm solo5_manifest_path

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
    Fmt.strf {json|{ "name": %S, "type": %S }|json} name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC")
  in
  let devices =
    if with_devices then List.map to_string (networks @ blocks) else []
  in
  let s = String.concat ~sep:", " devices in
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

let generate_manifest_c () =
  let json = solo5_manifest_path in
  let c = "_build/manifest.c" in
  let cmd =
    Bos.Cmd.(v "solo5-elftool" % "gen-manifest" % Fpath.to_string json % c)
  in
  Action.mkdir Fpath.(v "_build") >>= fun _created ->
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Action.run_cmd cmd

let configure i =
  let name = Info.name i in
  let target = Info.get i Key.target |> cast in
  ( match target with
  | #solo5_target -> generate_manifest_json true ()
  (* On Xen, a Solo5 manifest must be present to keep the build system and
     Solo5 happy, but we intentionally do not generate any devices[] as
     their naming does not follow the Solo5 rules. *)
  | #xen_target -> generate_manifest_json false () )
  >>= fun () ->
  match target with
  | `Xen ->
      Xen.configure_main_xl ~ext:"xl" i >>= fun () ->
      Xen.configure_main_xl ~substitutions:[] ~ext:"xl.in" i >>= fun () ->
      Libvirt.configure_main ~name
  | `Virtio -> Libvirt.configure_virtio ~name
  | _ -> Action.ok ()

let configure_files i =
  let target = Info.get i Key.target in
  match target with
  | `Virtio -> Fpath.[ v "_build/manifest.json"; v "libvirt.xml" ]
  | #solo5_target -> [ Fpath.v "_build/manifest.json" ]
  | `Xen -> Xen.files i
  | _ -> []

(** BUILD **)

let cflags pkg = pkg_config pkg [ "--cflags" ]

let compile_manifest target =
  let bindings = solo5_bindings_pkg target in
  let c = "_build/manifest.c" in
  let obj = "_build/manifest.o" in
  cflags bindings >>= fun cflags ->
  let cmd = Bos.Cmd.(v "cc" %% of_list cflags % "-c" % c % "-o" % obj) in
  Log.info (fun m -> m "executing %a" Bos.Cmd.pp cmd);
  Action.run_cmd cmd

let build i =
  let target = Info.get i Key.target |> cast in
  generate_manifest_c () >>= fun () -> compile_manifest target

(** LINK *)

let static_libs pkg_config_deps =
  pkg_config pkg_config_deps [ "--static"; "--libs" ]

let ldflags pkg = pkg_config pkg [ "--variable=ldflags" ]

let ldpostflags pkg = pkg_config pkg [ "--variable=ldpostflags" ]

let find_ld pkg =
  pkg_config pkg [ "--variable=ld" ] >|= function
  | ld :: _ ->
      Log.info (fun m ->
          m "using %s as ld (pkg-config %s --variable=ld)" ld pkg);
      ld
  | [] ->
      Log.warn (fun m ->
          m "pkg-config %s --variable=ld returned nothing, using ld" pkg);
      "ld"

let link ~name info =
  let libs = Info.libraries info in
  let target = Info.get info Key.target |> cast in
  let bindings = solo5_bindings_pkg target in
  let platform = solo5_platform_pkg target in
  extra_c_artifacts "freestanding" libs >>= fun c_artifacts ->
  static_libs platform >>= fun static_libs ->
  ldflags bindings >>= fun ldflags ->
  ldpostflags bindings >>= fun ldpostflags ->
  let extension = bin_extension target in
  let out = name ^ extension in
  find_ld bindings >>= fun ld ->
  let linker =
    Bos.Cmd.(
      v ld
      %% of_list ldflags
      % "_build/main.native.o"
      % "_build/manifest.o"
      %% of_list c_artifacts
      %% of_list static_libs
      % "-o"
      % out
      %% of_list ldpostflags)
  in
  Log.info (fun m -> m "linking with %a" Bos.Cmd.pp linker);
  Action.run_cmd linker >|= fun () -> out

(** INSTALL *)

let install i =
  let target = Info.get i Key.target |> cast in
  let name = match Info.output i with None -> Info.name i | Some n -> n in
  let bin =
    let ext = bin_extension target in
    let file = Fpath.v (name ^ ext) in
    (file, file)
  in
  let etc =
    let libvirt = Libvirt.filename ~name in
    match target with
    | `Xen -> Fpath.[ v name + "xl"; v name + "xl.in"; libvirt ]
    | `Virtio -> [ libvirt ]
    | _ -> []
  in
  Install.v ~bin:[ bin ] ~etc ()

let result = "main.native.o"

let dontlink = [ "unix"; "str"; "num"; "threads" ]

let ocamlbuild_tags = []

let clean i =
  let name = Info.name i in
  Xen.clean_main_xl ~name ~ext:"xl" >>= fun () ->
  Xen.clean_main_xl ~name ~ext:"xl.in" >>= fun () ->
  Xen.clean_main_xe ~name >>= fun () ->
  Libvirt.clean ~name >>= fun () -> clean_manifest ()
