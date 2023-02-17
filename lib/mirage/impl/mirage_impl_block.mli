type block

val block : block Functoria.typ

val generic_block :
  ?group:string ->
  ?key:[ `BlockFile | `Ramdisk | `XenstoreId ] Functoria.value ->
  string ->
  block Functoria.impl

val tar_kv_ro : block Functoria.impl -> Mirage_impl_kv.ro Functoria.impl
val archive : block Functoria.impl -> Mirage_impl_kv.ro Functoria.impl
val fat_ro : block Functoria.impl -> Mirage_impl_kv.ro Functoria.impl
val ramdisk : string -> block Functoria.impl
val block_of_xenstore_id : string -> block Functoria.impl
val block_of_file : string -> block Functoria.impl
val block_conf : string -> block Functoria.device

val docteur :
  ?mode:[ `Fast | `Light ] ->
  ?disk:string Functoria.Key.key ->
  ?analyze:bool Functoria.Key.key ->
  ?branch:string ->
  ?extra_deps:string list ->
  string ->
  Mirage_impl_kv.ro Functoria.impl

type block_t = { filename : string; number : int }

val all_blocks : (string, block_t) Hashtbl.t

val chamelon :
  program_block_size:int Functoria.key ->
  (block -> Mirage_impl_pclock.pclock -> Mirage_impl_kv.rw) Functoria.impl

val tar_kv_rw :
  Mirage_impl_pclock.pclock Functoria.impl ->
  block Functoria.impl ->
  Mirage_impl_kv.rw Functoria.impl

val ccm_block :
  ?nonce_len:int ->
  string option Functoria.key ->
  (block -> block) Functoria.impl
