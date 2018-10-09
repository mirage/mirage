open Functoria
module Name = Functoria_app.Name
module Key = Mirage_key
open Rresult
open Astring

type kv_ro = KV_RO
let kv_ro = Type KV_RO

let crunch dirname = impl @@ object
    inherit base_configurable
    method ty = kv_ro
    val name = Name.create ("static" ^ dirname) ~prefix:"static"
    method name = name
    method module_name = String.Ascii.capitalize name
    method! packages =
      Key.pure [ package "io-page"; package ~min:"2.0.0" ~build:true "crunch" ]
    method! deps = [ abstract Mirage_impl_io_page.default_io_page ]
    method! connect _ modname _ = Fmt.strf "%s.connect ()" modname
    method! build _i =
      let dir = Fpath.(v dirname) in
      let file = Fpath.(v name + "ml") in
      Bos.OS.Path.exists dir >>= function
      | true ->
        Mirage_impl_misc.Log.info (fun m -> m "Generating: %a" Fpath.pp file);
        Bos.OS.Cmd.run Bos.Cmd.(v "ocaml-crunch" % "-o" % p file % p dir)
      | false ->
        R.error_msg (Fmt.strf "The directory %s does not exist." dirname)
    method! clean _i =
      Bos.OS.File.delete Fpath.(v name + "ml") >>= fun () ->
      Bos.OS.File.delete Fpath.(v name + "mli")
  end

let direct_kv_ro_conf dirname = impl @@ object
    inherit base_configurable
    method ty = kv_ro
    val name = Name.create ("direct" ^ dirname) ~prefix:"direct"
    method name = name
    method module_name = "Kvro_fs_unix"
    method! packages = Key.pure [ package ~min:"1.3.0" "mirage-fs-unix" ]
    method! connect i _modname _names =
      let path = Fpath.(Info.build_dir i / dirname) in
      Fmt.strf "Kvro_fs_unix.connect \"%a\"" Fpath.pp path
  end

let direct_kv_ro dirname =
  match_impl Key.(value target) [
    `Xen, crunch dirname;
    `Qubes, crunch dirname;
    `Virtio, crunch dirname;
    `Hvt, crunch dirname;
    `Muen, crunch dirname
  ] ~default:(direct_kv_ro_conf dirname)
