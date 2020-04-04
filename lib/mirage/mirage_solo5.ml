open Functoria
open Action.Infix
open Astring
open Mirage_impl_misc
module Key = Mirage_key

let package = function
  | `Virtio -> "solo5-bindings-virtio"
  | `Muen -> "solo5-bindings-muen"
  | `Hvt -> "solo5-bindings-hvt"
  | `Genode -> "solo5-bindings-genode"
  | `Spt -> "solo5-bindings-spt"
  | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

let ext = function
  | `Virtio -> ".virtio"
  | `Muen -> ".muen"
  | `Hvt -> ".hvt"
  | `Genode -> ".genode"
  | `Spt -> ".spt"
  | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

let normalize p = Fpath.(to_string (normalize (v p)))

let static_libs pkg =
  pkg_config pkg [ "--static"; "--libs-only-l" ] >|= fun libs ->
  List.flatten @@ List.map (fun o -> [ "-cclib"; normalize o ]) libs

let ldflags pkg =
  pkg_config pkg [ "--variable=ldflags" ] >|= fun flags ->
  List.map normalize flags

let ldpostflags pkg =
  pkg_config pkg [ "--variable=ldpostflags" ] >|= fun flags ->
  List.map normalize flags

let cflags i =
  let target = Info.get i Key.target in
  let pkg = package target in
  pkg_config "mirage-solo5" [ "--cflags-only-I" ] >>= fun includes ->
  pkg_config pkg [ "--cflags-only-other" ] >|= fun others ->
  List.map normalize (includes @ others)

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

let generate_manifest () =
  let networks =
    List.map (fun n -> (n, `Network)) !Mirage_impl_network.all_networks
  in
  let blocks =
    Hashtbl.fold
      (fun k _v acc -> (k, `Block) :: acc)
      Mirage_impl_block.all_blocks []
  in
  let pp_device ppf (name, typ) =
    Fmt.pf ppf {|{ "name": %S, "type": %S }|} name
      (match typ with `Network -> "NET_BASIC" | `Block -> "BLOCK_BASIC")
  in
  let devices = networks @ blocks in
  let contents =
    Fmt.str
      {|{
  "type": "solo5.manifest",
  "version": 1,
  "devices": [ %a ]
}
|}
      Fmt.(list ~sep:(unit ", ") pp_device)
      devices
  in
  Action.write_file (Fpath.v "manifest.json") contents >>= fun () ->
  Action.write_file (Fpath.v "manifest.ml") ""

let build _ = generate_manifest ()

let files _ = List.map Fpath.v [ "manifest.json"; "manifest.ml" ]

let main i = Fpath.(base (rem_ext (Info.main i)))

let pp_list = Fmt.(list ~sep:(unit " ") string)

let out i =
  let target = Info.get i Key.target in
  let public_name =
    match Info.output i with None -> Info.name i | Some o -> o
  in
  public_name ^ ext target

let link i =
  let target = Info.get i Key.target in
  let main = Fpath.to_string (main i) in
  let pkg = package target in
  let out = out i in
  ldflags pkg >>= fun ldflags ->
  ldpostflags pkg >>= fun ldpostflags ->
  find_ld pkg >|= fun ld ->
  Dune.stanzaf
    {|
(rule
  (target %s)
  (mode (promote (until-clean)))
  (deps main.exe.o manifest.o)
  (action
    (run %s %a %s.exe.o manifest.o -o %%{target} %a)))
|}
    out ld pp_list ldflags main pp_list ldpostflags

let manifest () =
  Dune.stanzaf
    {|
(rule
  (targets manifest.c)
  (deps manifest.json)
  (action (run solo5-elftool gen-manifest manifest.json manifest.c)))

(library
  (name manifest)
  (modules manifest)
  (foreign_stubs
    (language c)
    (names manifest)))
|}

let install i =
  let out = out i in
  let package = Info.name i in
  Dune.stanzaf {|
(install
  (files %s)
  (section bin)
  (package %s))
|} out
    package

let main i =
  let libraries = Info.libraries i in
  let flags = Mirage_dune.flags i in
  let main = Fpath.to_string (main i) in
  static_libs "mirage-solo5" >|= fun static_libs ->
  Dune.stanzaf
    {|
(executable
  (name %s)
  (modes (native object))
  (libraries ocaml-freestanding %a)
  (link_flags %a)
  (modules (:standard \ config manifest))
  (forbidden_libraries unix)
  (flags %a)
  (variants freestanding))
|}
    main pp_list libraries pp_list static_libs pp_list flags

let dune i =
  main i >>= fun main ->
  link i >|= fun link -> [ main; manifest (); link; install i ]

let workspace i =
  let target = Info.get i Key.target in
  cflags i >|= fun cflags ->
  let dune =
    Dune.stanzaf
      {|
(context (default
  (name mirage-%a)
  (host default)
  (env (_ (c_flags (%a))))))
|}
      Key.pp_target target
      Fmt.(list ~sep:(unit " ") string)
      (":standard" :: cflags)
  in
  [ dune ]
