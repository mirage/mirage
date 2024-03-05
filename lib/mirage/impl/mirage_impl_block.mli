open Functoria

type block

val block : block typ

val generic_block :
  ?group:string ->
  ?key:[ `BlockFile | `Ramdisk | `XenstoreId ] value ->
  string ->
  block impl

val tar_kv_ro : block impl -> Mirage_impl_kv.ro impl
val fat_ro : block impl -> Mirage_impl_kv.ro impl
val ramdisk : string -> block impl
val block_of_xenstore_id : string -> block impl
val block_of_file : string -> block impl
val block_conf : string -> block device

val docteur :
  ?mode:[ `Fast | `Light ] ->
  ?name:string key ->
  ?output:string key ->
  ?analyze:bool runtime_arg ->
  ?branch:string ->
  ?extra_deps:string list ->
  string ->
  Mirage_impl_kv.ro impl

type block_t = { filename : string; number : int }

val all_blocks : (string, block_t) Hashtbl.t

val chamelon :
  program_block_size:int runtime_arg ->
  (block -> Mirage_impl_pclock.pclock -> Mirage_impl_kv.rw) impl

val tar_kv_rw :
  Mirage_impl_pclock.pclock impl -> block impl -> Mirage_impl_kv.rw impl

val ccm_block :
  ?nonce_len:int -> string option runtime_arg -> (block -> block) impl
