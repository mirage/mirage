type reporter = Functoria.job

val reporter : reporter Functoria.typ

val default_reporter :
  ?clock:Mirage_impl_pclock.pclock Functoria.impl ->
  ?ring_size:int ->
  ?level:Logs.level ->
  unit ->
  reporter Functoria.impl

val no_reporter : reporter Functoria.impl
