type ro

val ro : ro Functoria.typ

val direct_kv_ro : string -> ro Functoria.impl

val crunch : string -> ro Functoria.impl

type rw

val rw : rw Functoria.typ

val direct_kv_rw : string -> rw Functoria.impl

val mem_kv_rw :
  ?clock:Mirage_impl_pclock.pclock Functoria.impl -> unit -> rw Functoria.impl
