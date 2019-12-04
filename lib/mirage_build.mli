open Rresult

val ignore_dirs : string list
val build : Functoria.Info.t -> (unit, [> R.msg ]) result
