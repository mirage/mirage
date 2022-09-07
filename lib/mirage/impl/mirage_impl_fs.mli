type t

val typ : t Functoria.typ
val fat : Mirage_impl_block.block Functoria.impl -> t Functoria.impl
val kv_ro_of_fs : t Functoria.impl -> Mirage_impl_kv.ro Functoria.impl
