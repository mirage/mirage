type reporter = Functoria.job

val reporter : reporter Functoria.typ

val default_reporter :
  ?timestamp:bool
  -> ?clock:Mirage_impl_pclock.pclock Functoria.impl
  -> ?ring_size:int
  -> ?level:Logs.level
  -> ?style:Fmt.style_renderer
  -> ?channel:out_channel
  -> unit
  -> reporter Functoria.impl

val no_reporter : reporter Functoria.impl
