open Functoria
open Astring
module Key = Mirage_key

type ro = RO

let ro = Type.v RO

let crunch dirname =
  let name = "Static_" ^ String.Ascii.lowercase dirname in
  let packages =
    [
      package ~min:"3.0.0" ~max:"4.0.0" "mirage-kv-mem";
      package ~min:"3.1.0" ~max:"4.0.0" ~build:true "crunch";
    ]
  in
  let connect _ modname _ = Fmt.strf "%s.connect ()" modname in
  let dune _i =
    let dir = Fpath.(v dirname) in
    let file ext = Fpath.(v (String.Ascii.lowercase name) + ext) in
    let ml = file "ml" in
    let mli = file "mli" in
    let dune =
      Dune.stanzaf
        {|
(rule
  (targets %a %a)
  (deps (source_tree %a))
  (action
    (run ocaml-crunch -o %a %a)))
|}
        Fpath.pp ml Fpath.pp mli Fpath.pp dir Fpath.pp ml Fpath.pp dir
    in
    [ dune ]
  in
  impl ~packages ~connect ~dune name ro

let direct_kv_ro dirname =
  let packages = [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-kv-unix" ] in
  let connect _ modname _names = Fmt.strf "%s.connect \"%s\"" modname dirname in
  impl ~packages ~connect "Mirage_kv_unix" ro

let direct_kv_ro dirname =
  match_impl
    Key.(value target)
    [
      (`Xen, crunch dirname);
      (`Qubes, crunch dirname);
      (`Virtio, crunch dirname);
      (`Hvt, crunch dirname);
      (`Spt, crunch dirname);
      (`Muen, crunch dirname);
      (`Genode, crunch dirname);
    ]
    ~default:(direct_kv_ro dirname)

type rw = RW

let rw = Type.v RW

let direct_kv_rw dirname =
  let packages = [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-kv-unix" ] in
  let connect _ modname _names = Fmt.strf "%s.connect \"%s\"" modname dirname in
  impl ~packages ~connect "Mirage_kv_unix" rw

let mem_kv_rw_config =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-kv-mem" ] in
  let connect _ modname _names = Fmt.strf "%s.connect ()" modname in
  impl ~packages ~connect "Mirage_kv_mem.Make" (Mirage_impl_pclock.pclock @-> rw)

let mem_kv_rw ?(clock = Mirage_impl_pclock.default_posix_clock) () =
  mem_kv_rw_config $ clock
