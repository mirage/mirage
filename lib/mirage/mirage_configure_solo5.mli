open Functoria

val solo5_manifest_path : Fpath.t

val clean_manifest : unit -> unit Action.t

val bin_extension : [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> string

val solo5_bindings_pkg :
  [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> string

val solo5_platform_pkg :
  [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> string

val generate_manifest_json : bool -> unit -> unit Action.t

val generate_manifest_c : unit -> unit Action.t

val compile_manifest :
  [> Mirage_key.mode_solo5 | Mirage_key.mode_xen ] -> unit Action.t

val files : Info.t -> Fpath.t list
