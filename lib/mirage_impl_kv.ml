open Functoria
module Name = Functoria_app.Name
module Key = Mirage_key
open Rresult
open Astring

type ro = RO
let ro = Type RO

let crunch dirname = impl @@ object
    inherit base_configurable
    method ty = ro
    val name = Name.create ("static" ^ dirname) ~prefix:"static"
    method name = name
    method module_name = String.Ascii.capitalize name
    method! packages =
      Key.pure [
        package "mirage-kv-mem";
        package ~min:"3.0.0" ~max:"4.0.0" ~build:true "crunch"
      ]
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

let direct_kv_ro dirname = impl @@ object
    inherit base_configurable
    method ty = ro
    val name = Name.create ("direct-kv-ro-" ^ dirname) ~prefix:"direct"
    method name = name
    method module_name = "Mirage_kv_unix"
    method! packages =
      Key.pure [ package ~min:"2.0.0" ~max:"3.0.0" "mirage-kv-unix" ]
    method! connect i modname _names =
      let path = Fpath.(Info.build_dir i / dirname) in
      Fmt.strf "%s.connect \"%a\"" modname Fpath.pp path
  end

let direct_kv_ro dirname =
  match_impl Key.(value target) [
    `Xen, crunch dirname;
    `Qubes, crunch dirname;
    `Virtio, crunch dirname;
    `Hvt, crunch dirname;
    `Spt, crunch dirname;
    `Muen, crunch dirname;
    `Genode, crunch dirname
  ] ~default:(direct_kv_ro dirname)

type rw = RW
let rw = Type RW

let direct_kv_rw dirname = impl @@ object
    inherit base_configurable
    method ty = rw
    val name = Name.create ("direct-kv-rw-" ^ dirname) ~prefix:"direct"
    method name = name
    method module_name = "Mirage_kv_unix"
    method! packages =
      Key.pure [ package ~min:"2.0.0" ~max:"3.0.0" "mirage-kv-unix" ]
    method! connect i modname _names =
      let path = Fpath.(Info.build_dir i / dirname) in
      Fmt.strf "%s.connect \"%a\"" modname Fpath.pp path
  end

let mem_kv_rw_config = impl @@ object
    inherit base_configurable
    method ty = Mirage_impl_pclock.pclock @-> rw
    method name = "mirage-kv-mem"
    method module_name = "Mirage_kv_mem.Make"
    method! packages =
      Key.pure [ package ~min:"2.0.0" ~max:"3.0.0" "mirage-kv-mem" ]
    method! connect _i modname _names =
      Fmt.strf "%s.connect ()" modname
  end

let mem_kv_rw ?(clock = Mirage_impl_pclock.default_posix_clock) () =
  mem_kv_rw_config $ clock
