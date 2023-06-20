open Functoria.DSL

val register :
  ?init:job impl list ->
  ?src:[ `Auto | `None | `Some of string ] ->
  string ->
  job impl list ->
  unit

val run : unit -> unit
