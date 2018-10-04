val output_main_xl :
  Format.formatter ->
  name:string ->
  kernel:string ->
  memory:string ->
  blocks:(int * string) list ->
  networks:string list ->
  unit
