open Rresult

val filename : name:string -> Fpath.t
val configure_main : root:string -> name:string -> (unit, [> R.msg ]) result
val configure_virtio : root:string -> name:string -> (unit, [> R.msg ]) result
val clean : name:string -> (unit, [> R.msg ]) result
