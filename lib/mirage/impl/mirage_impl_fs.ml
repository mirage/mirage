open Functoria
open Mirage_impl_block
open Mirage_impl_misc
module Key = Mirage_key

type t = FS

let typ = Type.v FS
let fat_pkg = package ~min:"0.14.0" ~max:"0.15.0" "fat-filesystem"

let connect err _ modname l =
  match l with
  | [ block_name ] -> Fmt.str "%s.connect %s" modname block_name
  | _ -> failwith (connect_err err 1)

let fat_conf =
  let packages = [ fat_pkg ] in
  impl ~connect:(connect "fat") ~packages "Fat.FS" (block @-> typ)

let fat block = fat_conf $ block

let kv_ro_of_fs_conf =
  let packages = [ package ~min:"3.0.0" ~max:"4.0.0" "mirage-fs" ] in
  let connect _ modname = function
    | [ fs ] -> Fmt.str "%s.connect %s" modname fs
    | _ -> failwith (connect_err "kv_ro_of_fs" 1)
  in
  impl ~packages ~connect "Mirage_fs.To_KV_RO" (typ @-> Mirage_impl_kv.ro)

let kv_ro_of_fs x = kv_ro_of_fs_conf $ x

(** generic kv_ro. *)

let generic_kv_ro ?group ?(key = Key.value @@ Key.kv_ro ?group ()) dir =
  match_impl key
    [
      (`Crunch, Mirage_impl_kv.crunch dir);
      (`Direct, Mirage_impl_kv.direct_kv_ro dir);
    ]
    ~default:(Mirage_impl_kv.direct_kv_ro dir)
