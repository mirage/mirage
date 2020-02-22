open Functoria
open Rresult
open Astring
module Key = Mirage_key

type ro = RO

let ro = Type.v RO

let crunch dirname =
  let name = "Static" in
  let packages =
    [
      package ~min:"3.0.0" ~max:"4.0.0" "mirage-kv-mem";
      package ~min:"3.1.0" ~max:"4.0.0" ~build:true "crunch";
    ]
  in
  let connect _ modname _ = Fmt.strf "%s.connect ()" modname in
  let build _i =
    let dir = Fpath.(v dirname) in
    let file = Fpath.(v (String.Ascii.lowercase name) + "ml") in
    Bos.OS.Path.exists dir >>= function
    | true ->
        Mirage_impl_misc.Log.info (fun m -> m "Generating: %a" Fpath.pp file);
        Bos.OS.Cmd.run Bos.Cmd.(v "ocaml-crunch" % "-o" % p file % p dir)
    | false -> R.error_msg (Fmt.strf "The directory %s does not exist." dirname)
  in
  let clean _i =
    Bos.OS.File.delete Fpath.(v name + "ml") >>= fun () ->
    Bos.OS.File.delete Fpath.(v name + "mli")
  in
  impl ~packages ~connect ~build ~clean name ro

let direct_kv_ro dirname =
  let packages = [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-kv-unix" ] in
  let connect i modname _names =
    let path = Fpath.(Info.build_dir i / dirname) in
    Fmt.strf "%s.connect \"%a\"" modname Fpath.pp path
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

let rw = Type.v RW

let direct_kv_rw dirname =
  let packages = [ package ~min:"2.1.0" ~max:"3.0.0" "mirage-kv-unix" ] in
  let connect i modname _names =
    let path = Fpath.(Info.build_dir i / dirname) in
    Fmt.strf "%s.connect \"%a\"" modname Fpath.pp path
  in
  impl ~packages ~connect "Mirage_kv_unix" rw

let mem_kv_rw_config =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-kv-mem" ] in
  let connect _ modname _names = Fmt.strf "%s.connect ()" modname in
  impl ~packages ~connect "Mirage_kv_mem.Make" (Mirage_impl_pclock.pclock @-> rw)

let mem_kv_rw ?(clock = Mirage_impl_pclock.default_posix_clock) () =
  mem_kv_rw_config $ clock
