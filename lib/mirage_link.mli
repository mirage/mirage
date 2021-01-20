open Rresult

val link : Functoria.Info.t -> string -> Mirage_key.mode -> bool -> (string, [> R.msg ]) result
