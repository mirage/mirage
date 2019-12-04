open Rresult

val link : Functoria.Info.t -> string -> Mirage_key.mode -> bool -> (unit, [> R.msg ]) result
