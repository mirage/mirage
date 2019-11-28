open Rresult

val solo5_manifest_path : Fpath.t
val clean_manifest : unit -> (unit, [> R.msg ]) result

val solo5_pkg : [> Mirage_key.mode_solo5 ] -> string * string

val generate_manifest_json : unit -> (unit, [> R.msg ]) result
val generate_manifest_c : unit -> (unit, [> R.msg ]) result
val compile_manifest : [> Mirage_key.mode_solo5 ] -> (unit, [> R.msg ]) result

val ignore_dirs : string list
