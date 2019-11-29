open Rresult

val configure_main_libvirt_xml : root:string -> name:string -> (unit, [> R.msg ]) result
val configure_virtio_libvirt_xml : root:string -> name:string -> (unit, [> R.msg ]) result
val clean_main_libvirt_xml : name:string -> (unit, [> R.msg ]) result
