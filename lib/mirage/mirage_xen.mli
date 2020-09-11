open Functoria

val dune : Info.t -> Dune.stanza list

val configure : Info.t -> unit Action.t

val workspace : Info.t -> Dune.stanza list
