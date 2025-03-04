module Dune = Functoria.Dune
open Functoria.DSL

type ro = RO

let ro = typ RO

let crunch dirname =
  let is_valid = function
    | '0' .. '9' | 'a' .. 'z' | 'A' .. 'Z' -> true
    | _ -> false
  in
  let name =
    let modname = String.map (fun c -> if is_valid c then c else '_') dirname in
    "Static_" ^ String.lowercase_ascii modname
  in
  let packages =
    [
      package ~min:"4.0.0" ~max:"5.0.0" "mirage-kv-mem";
      package ~min:"4.0.0" ~max:"5.0.0" ~build:true "crunch";
    ]
  in
  let connect _ modname _ = code ~pos:__POS__ "%s.connect ()" modname in
  let dune _i =
    let dir = Fpath.(v dirname) in
    let file ext = Fpath.(v name + ext) in
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
  let connect _ modname _names =
    code ~pos:__POS__ "%s.connect \"%s\"" modname dirname
  in
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

let rw = typ RW

let direct_kv_rw dirname =
  let packages = [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-kv-unix" ] in
  let connect _ modname _names =
    code ~pos:__POS__ "%s.connect \"%s\"" modname dirname
  in
  impl ~packages ~connect "Mirage_kv_unix" rw

let mem_kv_rw () =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-kv-mem" ] in
  let connect _ modname _names = code ~pos:__POS__ "%s.connect ()" modname in
  impl ~packages ~connect "Mirage_kv_mem" rw

(** generic kv_ro. *)

let generic_kv_ro ?group ?(key = Key.value @@ Key.kv_ro ?group ()) dir =
  match_impl key
    [ (`Crunch, crunch dir); (`Direct, direct_kv_ro dir) ]
    ~default:(direct_kv_ro dir)
