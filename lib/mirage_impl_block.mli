open Functoria.DSL

type block

val block : block typ

val generic_block :
     ?group:string
  -> ?key:[`BlockFile | `Ramdisk | `XenstoreId] value
  -> string
  -> block impl

val archive_of_files :
  ?dir:string -> unit -> Mirage_impl_kv.ro impl

val archive : block impl -> Mirage_impl_kv.ro impl

val ramdisk : string -> block impl

val block_of_xenstore_id : string -> block impl

val block_of_file : string -> block impl

class block_conf :
  string
  -> object
       inherit base_configurable

       method module_name : string

       method name : string

       method ty : block typ
     end

type block_t = {filename: string; number: int}

val all_blocks : (string, block_t) Hashtbl.t
