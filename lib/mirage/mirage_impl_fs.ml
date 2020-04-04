open Functoria
open Mirage_impl_block
open Mirage_impl_misc
open Action.Infix
module Key = Mirage_key

type t = FS

let typ = Type.v FS

let fat_pkg = package ~min:"0.14.0" ~max:"0.15.0" "fat-filesystem"

let connect err _ modname l =
  match l with
  | [ block_name ] -> Fmt.strf "%s.connect %s" modname block_name
  | _ -> failwith (connect_err err 1)

let fat_conf =
  let packages = [ fat_pkg ] in
  impl ~connect:(connect "fat") ~packages "Fat.FS" (block @-> typ)

let fat block = fat_conf $ block

let fat_shell_script fmt ~block_file ~dir ~regexp =
  Fmt.pf fmt
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
echo Created '%s'
|}
    block_file Fpath.pp dir regexp block_file

let count =
  let i = ref 0 in
  fun () ->
    incr i;
    !i

let fat_block ?(dir = ".") ?(regexp = "*") () =
  let name = "fat_block" ^ string_of_int (count ()) in
  let block_file = name ^ ".img" in
  let file = Fmt.strf "make-%s-image.sh" name in
  let files _ = [ Fpath.v block_file ] in
  let pre_build _ =
    let dir = Fpath.of_string dir |> Rresult.R.error_msg_to_invalid_arg in
    Log.info (fun m -> m "Generating block generator script: %s" file);
    Action.with_output ~mode:0o755 ~path:(Fpath.v file)
      ~purpose:"fat shell script" (fun fmt ->
        fat_shell_script fmt ~block_file ~dir ~regexp)
    >>= fun () ->
    Log.info (fun m -> m "Executing block generator script: ./%s" file);
    Action.run_cmd (Bos.Cmd.v file)
  in
  let packages = [ fat_pkg ] in
  let block = Mirage_impl_block.block_conf block_file in
  of_device @@ Device.extend ~packages ~pre_build ~files block

let fat_of_files ?dir ?regexp () = fat @@ fat_block ?dir ?regexp ()

let kv_ro_of_fs_conf =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-fs" ] in
  let connect _ modname = function
    | [ fs ] -> Fmt.strf "%s.connect %s" modname fs
    | _ -> failwith (connect_err "kv_ro_of_fs" 1)
  in
  impl ~packages ~connect "Mirage_fs.To_KV_RO" (typ @-> Mirage_impl_kv.ro)

let kv_ro_of_fs x = kv_ro_of_fs_conf $ x

(** generic kv_ro. *)

let generic_kv_ro ?group ?(key = Key.value @@ Key.kv_ro ?group ()) dir =
  match_impl key
    [
      (`Fat, kv_ro_of_fs @@ fat_of_files ~dir ());
      (`Archive, archive_of_files ~dir ());
      (`Crunch, Mirage_impl_kv.crunch dir);
      (`Direct, Mirage_impl_kv.direct_kv_ro dir);
    ]
    ~default:(Mirage_impl_kv.direct_kv_ro dir)
