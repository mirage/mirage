open Functoria.DSL

type reporter = job

val reporter : reporter typ
val default_reporter : ?level:Logs.level option -> unit -> reporter impl
val no_reporter : reporter impl
