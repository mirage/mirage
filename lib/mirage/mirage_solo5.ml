open Functoria
open Action.Infix
open Astring
module Key = Mirage_key

let package = function
  | `Virtio -> "solo5-virtio"
  | `Muen -> "solo5-muen"
  | `Hvt -> "solo5-hvt"
  | `Genode -> "solo5--genode"
  | `Spt -> "solo5-spt"
  | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

let ext = function
  | `Virtio -> ".virtio"
  | `Muen -> ".muen"
  | `Hvt -> ".hvt"
  | `Genode -> ".genode"
  | `Spt -> ".spt"
  | _ -> invalid_arg "solo5 bindings only defined for solo5 targets"

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

let configure _ = generate_manifest ()

let main i = Fpath.(base (rem_ext (Info.main i)))

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
  Dune.stanzaf
    {|
(rule (copy %%{lib:%s:ldflags} %s-ldflags))

(rule
 (target %s)
 (enabled_if (= %%{context_name} "mirage-%a"))
 (mode (promote (until-clean)))
 (deps main.exe.o (package %s) %s-ldflags)
 (action
  (bash
   "ld %s.exe.o -o %%{target} $(cat %s-ldflags)")))
|}
    pkg pkg out Key.pp_target target pkg pkg main pkg

let manifest _i =
  Dune.stanzaf
    {|
(rule
 (targets manifest.c)
 (deps manifest.json (package solo5))
 (action
  (run solo5-elftool gen-manifest manifest.json manifest.c)))
|}

let install i =
  let out = out i in
  let target = Info.get i Key.target in
  let package = Info.name i in
  Dune.stanzaf
    {|
(install
 (files %s)
 (enabled_if (= %%{context_name} "mirage-%a"))
 (section bin)
 (package %s))
|}
    out Key.pp_target target package

(* FIXME: should be generated in the root dune only *)
let workspace_flags i =
  let target = Info.get i Key.target in
  let pkg = package target in
  Dune.stanzaf
    {|
(rule
 (deps (package solo5))
 (action
  (copy %%{lib:%s:cflags} %s-cflags)))
|}
    pkg pkg

let main i =
  let libraries = Info.libraries i in
  let flags = "-without-runtime" :: Mirage_dune.flags i in
  let target = Info.get i Key.target in
  let main = Fpath.to_string (main i) in
  let pp_list f = Dune.compact_list f in
  Dune.stanzaf
    {|
(executable
 (enabled_if (= %%{context_name} "mirage-%a"))
 (name %s)
 (modes (native object))
 (libraries %a)
 (link_flags %a)
 (modules (:standard \ config manifest))
 (foreign_stubs (language c) (names manifest))
 (forbidden_libraries unix))
|}
    Key.pp_target target main (pp_list "libraries") libraries
    (pp_list "link_flags") flags

let dune i = [ main i; manifest i; link i; workspace_flags i; install i ]

let workspace i =
  let target = Info.get i Key.target in
  let pkg = package target in
  let profile_release = Dune.stanza "(profile release)" in
  let context =
    Dune.stanzaf
      {|
(context (default
  (name mirage-%a)
  (host default)
  (disable_dynamically_linked_foreign_archives true)
  (env (_ (c_flags (:include %s-cflags))))))
|}
      Key.pp_target target pkg
  in
  [ profile_release; context ]
