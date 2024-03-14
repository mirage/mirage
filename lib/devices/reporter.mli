open Functoria

type reporter = job

val reporter : reporter typ

val default_reporter :
  ?clock:Pclock.pclock impl -> ?level:Logs.level option -> unit -> reporter impl

val no_reporter : reporter impl
