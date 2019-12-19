open Functoria.DSL

type t

val typ : t typ

val fat : Mirage_impl_block.block impl -> t impl

val fat_of_files : ?dir:string -> ?regexp:string -> unit -> t impl

val kv_ro_of_fs : t impl -> Mirage_impl_kv.ro impl

val generic_kv_ro :
     ?group:string
  -> ?key:[`Archive | `Crunch | `Direct | `Fat] value
  -> string
  -> Mirage_impl_kv.ro impl

val fat_shell_script :
     Format.formatter
  -> block_file:string
  -> root:Fpath.t
  -> dir:Fpath.t
  -> regexp:string
  -> unit
