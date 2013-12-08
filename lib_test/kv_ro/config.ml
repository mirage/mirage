open Mirage

let kv_ro name dirname =
  Driver.KV_RO { KV_RO.name; dirname }

let x = kv_ro "x" "t"

let y = kv_ro "y" "t"

let () =
  Job.register [
    "Handler.Main",  [Driver.console; x; y]
  ]
