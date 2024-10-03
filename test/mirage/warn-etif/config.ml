open Mirage

module T : sig end = struct
  type t = ()
  type t' = ()
end

let rec eth = etif default_network
let main = main "App.Make" ~pos:__POS__ (ethernet @-> job)

let () =
  let ramdisk (conf : syslog_config) =
    match conf with { hostname } -> ramdisk "secrets\f42"
  in
  register "etif" [ main $ eth ]
