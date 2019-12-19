open Functoria.DSL

type ro

val ro : ro typ

val direct_kv_ro : string -> ro impl

val crunch : string -> ro impl

type rw

val rw : rw typ

val direct_kv_rw : string -> rw impl

val mem_kv_rw : ?clock:Mirage_impl_pclock.pclock impl -> unit -> rw impl
