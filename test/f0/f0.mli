open Functoria.DSL

val register :
  ?packages:package list ->
  ?keys:abstract_key list ->
  ?init:job impl list ->
  ?src:[ `Auto | `None | `Some of string ] ->
  string ->
  job impl list ->
  unit

val run_with_argv :
  ?help_ppf:Format.formatter ->
  ?err_ppf:Format.formatter ->
  string array ->
  unit
