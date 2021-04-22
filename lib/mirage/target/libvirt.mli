open Functoria

val filename : name:string -> Fpath.t

val configure_main : name:string -> unit Action.t

val configure_virtio : name:string -> unit Action.t
