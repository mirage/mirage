open Functoria

val solo5_manifest_path : Fpath.t

val clean_manifest : unit -> unit Action.t

val solo5_pkg : [> Mirage_key.mode_solo5 ] -> string * string

val generate_manifest_json : unit -> unit Action.t

val generate_manifest_c : unit -> unit Action.t

val compile_manifest : [> Mirage_key.mode_solo5 ] -> unit Action.t

val files : Info.t -> Fpath.t list
