type t

val typ : t Functoria.typ

val fat : Mirage_impl_block.block Functoria.impl -> t Functoria.impl

val fat_of_files : ?dir:string -> ?regexp:string -> unit -> t Functoria.impl

val kv_ro_of_fs : t Functoria.impl -> Mirage_impl_kv.ro Functoria.impl

val generic_kv_ro :
  ?group:string ->
  ?key:[ `Archive | `Crunch | `Direct | `Fat ] Functoria.value ->
  string ->
  Mirage_impl_kv.ro Functoria.impl

val fat_shell_script :
  Format.formatter -> block_file:string -> dir:Fpath.t -> regexp:string -> unit
