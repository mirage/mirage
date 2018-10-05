val output_main_xl :
  Format.formatter ->
  name:string ->
  kernel:string ->
  memory:string ->
  blocks:(int * string) list ->
  networks:string list ->
  unit

val output_main_xe :
  Format.formatter ->
  root:string ->
  name:string ->
  blocks:(string * int) list ->
  unit

val output_main_libvirt_xml :
  Format.formatter ->
  root:string ->
  name:string ->
  unit

val output_virtio_libvirt_xml :
  Format.formatter ->
  root:string ->
  name:string ->
  unit

val output_opam :
  Format.formatter ->
  name:string ->
  info:Functoria.Info.t ->
  unit

val output_fat :
  Format.formatter ->
  block_file:string ->
  root:Fpath.t ->
  dir:Fpath.t ->
  regexp:string ->
  unit
