open Functoria
module Codegen = Functoria_app.Codegen
module Key = Mirage_key
module Name = Functoria_app.Name
open Mirage_impl_block
open Mirage_impl_misc
open Rresult

type t = FS

let typ = Type FS

let fat_pkg = package ~min:"0.14.0" ~max:"0.15.0" "fat-filesystem"

let fat_conf = impl @@ object
    inherit base_configurable
    method ty = block @-> typ
    method! packages = Mirage_key.pure [ fat_pkg ]
    method name = "fat"
    method module_name = "Fat.FS"
    method! connect _ modname l =
      match l with
      | [block_name] ->
        Fmt.strf "%s.connect %s" modname block_name
      | _ ->
        failwith (connect_err "fat" 1)
  end

let fat block = fat_conf $ block

let fat_shell_script fmt ~block_file ~root ~dir ~regexp =
  let open Functoria_app.Codegen in
  append fmt
    {|#!/bin/sh

echo This uses the 'fat' command-line tool to build a simple FAT
echo filesystem image.

FAT=$(which fat)
if [ ! -x "${FAT}" ]; then
  echo I couldn\'t find the 'fat' command-line tool.
  echo Try running 'opam install fat-filesystem'
  exit 1
fi

IMG=$(pwd)/%s
rm -f ${IMG}
cd %a
SIZE=$(du -s . | cut -f 1)
${FAT} create ${IMG} ${SIZE}KiB
${FAT} add ${IMG} %s
echo Created '%s'|}
    block_file Fpath.pp (Fpath.append root dir) regexp block_file

let fat_block ?(dir = ".") ?(regexp = "*") () =
  let name =
    Name.(
      ocamlify @@ create (Fmt.strf "fat%s:%s" dir regexp) ~prefix:"fat_block")
  in
  let block_file = name ^ ".img" in
  impl @@ object
    inherit Mirage_impl_block.block_conf block_file as super
    method! packages = Key.map (List.cons fat_pkg) super#packages
    method! build i =
      let root = Info.build_dir i in
      let file = Fmt.strf "make-%s-image.sh" name in
      let dir = Fpath.of_string dir |> R.error_msg_to_invalid_arg in
      Log.info (fun m -> m "Generating block generator script: %s" file);
      with_output ~mode:0o755 (Fpath.v file)
        (fun oc () ->
           let fmt = Format.formatter_of_out_channel oc in
           fat_shell_script fmt ~block_file ~root ~dir ~regexp;
           R.ok () )
        "fat shell script"
      >>= fun () ->
      Log.info (fun m -> m "Executing block generator script: ./%s" file);
      Bos.OS.Cmd.run (Bos.Cmd.v ("./" ^ file)) >>= fun () -> super#build i
    method! clean i =
      let file = Fmt.strf "make-%s-image.sh" name in
      Bos.OS.File.delete (Fpath.v file)
      >>= fun () ->
      Bos.OS.File.delete (Fpath.v block_file) >>= fun () -> super#clean i
  end

let fat_of_files ?dir ?regexp () = fat @@ fat_block ?dir ?regexp ()

let kv_ro_of_fs_conf =
  impl @@ object
    inherit base_configurable
    method ty = typ @-> Mirage_impl_kv.ro
    method name = "kv_ro_of_fs"
    method module_name = "Mirage_fs.To_KV_RO"
    method! packages =
      Key.pure [package ~min:"3.0.0" ~max:"4.0.0" "mirage-fs"]
    method! connect _ modname = function
      | [fs] -> Fmt.strf "%s.connect %s" modname fs
      | _ -> failwith (connect_err "kv_ro_of_fs" 1)
  end

let kv_ro_of_fs x = kv_ro_of_fs_conf $ x

(** generic kv_ro. *)

let generic_kv_ro ?group ?(key = Key.value @@ Key.kv_ro ?group ()) dir =
  match_impl key
    [ (`Fat, kv_ro_of_fs @@ fat_of_files ~dir ())
    ; (`Archive, archive_of_files ~dir ())
    ; (`Crunch, Mirage_impl_kv.crunch dir)
    ; (`Direct, Mirage_impl_kv.direct_kv_ro dir) ]
    ~default:(Mirage_impl_kv.direct_kv_ro dir)
