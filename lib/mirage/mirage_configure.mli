open Functoria

val myocamlbuild_path : Fpath.t

val configure_myocamlbuild : unit -> unit Action.t

val clean_myocamlbuild : unit -> unit Action.t

val unikernel_opam_name : name:string -> Mirage_key.mode -> string

val opam_path : name:string -> Fpath.t

val opam_name : name:string -> target:string -> string

val configure_opam : name:string -> Functoria.Info.t -> unit Action.t

val clean_opam : name:string -> Mirage_key.mode -> unit Action.t

val configure_makefile : no_depext:bool -> opam_name:string -> unit Action.t

val configure : Functoria.Info.t -> unit Action.t
