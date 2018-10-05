type fs

val fs : fs Functoria.typ

val fat : Mirage_impl_block.block Functoria.impl -> fs Functoria.impl

val fat_of_files : ?dir:string -> ?regexp:string -> unit -> fs Functoria.impl

val kv_ro_of_fs : fs Functoria.impl -> Mirage_impl_kv_ro.kv_ro Functoria.impl

val generic_kv_ro :
     ?group:string
  -> ?key:[`Archive | `Crunch | `Direct | `Fat] Functoria.value
  -> string
  -> Mirage_impl_kv_ro.kv_ro Functoria.impl

val fat_shell_script :
     Format.formatter
  -> block_file:string
  -> root:Fpath.t
  -> dir:Fpath.t
  -> regexp:string
  -> unit
