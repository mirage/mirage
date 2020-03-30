open Functoria

val myocamlbuild_path : Fpath.t

val configure_myocamlbuild : unit -> unit Action.t

val clean_myocamlbuild : unit -> unit Action.t

val configure : Functoria.Info.t -> unit Action.t
