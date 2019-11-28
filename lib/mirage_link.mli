open Rresult

val static_libs : string -> (string list, [> R.msg ]) result
val ldflags : string -> (string list, [> R.msg ]) result
val ldpostflags : string -> (string list, [> R.msg ]) result

val find_ld : string -> string

val link : Functoria.Info.t -> string -> Mirage_key.mode -> bool -> (string, [> R.msg ]) result
