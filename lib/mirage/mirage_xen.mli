open Functoria

val dune : name:string -> Info.t -> Dune.stanza list

val configure : Info.t -> unit Action.t

val workspace : Info.t -> Dune.stanza list
