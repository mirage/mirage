include Functoria_app.DSL

val run: unit -> unit

val run_with_argv:
  ?help_ppf:Format.formatter -> ?err_ppf:Format.formatter ->
  string array -> unit

val register:
  ?packages:package list ->
  ?keys:key list ->
  ?init:job impl list ->
  string -> job impl list -> unit
