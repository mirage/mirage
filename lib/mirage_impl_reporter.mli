open Functoria.DSL

type reporter = job

val reporter : reporter typ

val default_reporter :
     ?clock:Mirage_impl_pclock.pclock impl
  -> ?ring_size:int
  -> ?level:Logs.level
  -> unit
  -> reporter impl

val no_reporter : reporter impl
