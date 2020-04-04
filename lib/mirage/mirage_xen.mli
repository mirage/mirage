open Functoria

val dune : Info.t -> Dune.stanza list Action.t

val files : Info.t -> Fpath.t list

val build : Info.t -> unit Action.t

val workspace : Info.t -> Dune.stanza list Action.t
