open Functoria

val dune : Info.t -> Dune.stanza list Action.t

val files : Info.t -> Fpath.t list

val build : Info.t -> unit Action.t

val package : Mirage_key.mode_solo5 -> string

val workspace : Info.t -> Dune.stanza list Action.t
