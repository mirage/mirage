open Functoria

val dune : name:string -> Info.t -> Dune.stanza list

val configure : Info.t -> unit Action.t

val package : Mirage_key.mode_solo5 -> string

val workspace : ?build_dir:Fpath.t -> Info.t -> Dune.stanza list
