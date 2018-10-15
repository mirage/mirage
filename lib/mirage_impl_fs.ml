module Codegen = Functoria_app.Codegen
module Key = Mirage_key
module Name = Functoria_app.Name
open Functoria
open Mirage_impl_block
open Mirage_impl_kv_ro
open Mirage_impl_misc
open Rresult

type fs = FS

let fs = Type FS

let fat_conf =
  impl
  @@ object
       inherit base_configurable

       method ty = block @-> fs

       method! packages = Key.pure [package ~min:"0.12.0" "fat-filesystem"]

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
  append fmt "#!/bin/sh";
  append fmt "";
  append fmt
    "echo This uses the 'fat' command-line tool to build a simple FAT";
  append fmt "echo filesystem image.";
  append fmt "";
  append fmt "FAT=$(which fat)";
  append fmt "if [ ! -x \"${FAT}\" ]; then";
  append fmt "  echo I couldn\\'t find the 'fat' command-line tool.";
  append fmt "  echo Try running 'opam install fat-filesystem'";
  append fmt "  exit 1";
  append fmt "fi";
  append fmt "";
  append fmt "IMG=$(pwd)/%s" block_file;
  append fmt "rm -f ${IMG}";
  append fmt "cd %a" Fpath.pp (Fpath.append root dir);
  append fmt "SIZE=$(du -s . | cut -f 1)";
  append fmt "${FAT} create ${IMG} ${SIZE}KiB";
  append fmt "${FAT} add ${IMG} %s" regexp;
  append fmt "echo Created '%s'" block_file

let fat_block ?(dir = ".") ?(regexp = "*") () =
  let name =
    Name.(
      ocamlify @@ create (Fmt.strf "fat%s:%s" dir regexp) ~prefix:"fat_block")
  in
  let block_file = name ^ ".img" in
  impl
  @@ object
       inherit Mirage_impl_block.block_conf block_file as super

       method! packages =
         Key.map
           (List.cons (package ~min:"0.12.0" ~build:true "fat-filesystem"))
           super#packages

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
  impl
  @@ object
       inherit base_configurable

       method ty = fs @-> kv_ro

       method name = "kv_ro_of_fs"

       method module_name = "Mirage_fs_lwt.To_KV_RO"

       method! packages = Key.pure [package "mirage-fs-lwt"]

       method! connect _ modname =
         function
         | [fs] ->
             Fmt.strf "%s.connect %s" modname fs
         | _ ->
             failwith (connect_err "kv_ro_of_fs" 1)
     end

let kv_ro_of_fs x = kv_ro_of_fs_conf $ x

(** generic kv_ro. *)

let generic_kv_ro ?group ?(key = Key.value @@ Key.kv_ro ?group ()) dir =
  match_impl key
    [ (`Fat, kv_ro_of_fs @@ fat_of_files ~dir ())
    ; (`Archive, archive_of_files ~dir ())
    ; (`Crunch, crunch dir)
    ; (`Direct, direct_kv_ro dir) ]
    ~default:(direct_kv_ro dir)
