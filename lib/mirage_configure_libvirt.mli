open Rresult

val filename : name:string -> Fpath.t
val configure_main : Functoria.Info.t -> (unit, [> R.msg ]) result
val configure_virtio : Functoria.Info.t -> (unit, [> R.msg ]) result
val clean : name:string -> (unit, [> R.msg ]) result
