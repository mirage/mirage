open Functoria

val compile :
  string list -> string list -> bool -> Mirage_key.mode -> unit Action.t

val build : Functoria.Info.t -> unit Action.t
