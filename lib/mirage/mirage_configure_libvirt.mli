open Functoria

val filename : name:string -> Fpath.t

val configure_main : root:string -> name:string -> unit Action.t

val configure_virtio : root:string -> name:string -> unit Action.t

val clean : name:string -> unit Action.t
