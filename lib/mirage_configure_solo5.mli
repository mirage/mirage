open Rresult

val solo5_manifest_path : Fpath.t
val clean_manifest : unit -> (unit, [> R.msg ]) result

val solo5_bindings_pkg : [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> string * string
val solo5_platform_pkg : [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> string

val generate_manifest_json : bool -> unit -> (unit, [> R.msg ]) result
val generate_manifest_c : unit -> (unit, [> R.msg ]) result
val compile_manifest : [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> (unit, [> R.msg ]) result
