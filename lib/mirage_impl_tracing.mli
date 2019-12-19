open Functoria.DSL

type tracing = job

val tracing : tracing typ

val mprof_trace : size:int -> unit -> tracing impl
