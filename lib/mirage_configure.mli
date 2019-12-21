open Rresult

val myocamlbuild_path : Fpath.t
val configure_myocamlbuild : unit -> (unit, [> R.msg ]) result
val clean_myocamlbuild : unit -> (unit, [> R.msg ]) result

val unikernel_opam_name : name:string -> Mirage_key.mode -> string

val opam_path : name:string -> Fpath.t
val opam_name : name:string -> target:string -> string
val configure_opam : Functoria.Info.t -> (unit, [> R.msg ]) result
val clean_opam : name:string -> Mirage_key.mode -> (unit, [> R.msg ]) result

val configure_makefile :
  no_depext:bool -> opam_name:string -> Functoria.Info.t -> (unit, [> R.msg ]) result

val configure : Functoria.Info.t -> (unit, [> R.msg ]) result
