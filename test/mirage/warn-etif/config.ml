open Mirage

(* This file exercises as many warnings as possible. It is thus a very poor
   example of a config.ml file. *)

module T : sig end = struct
  type t = ()
  type t' = ()
end

let rec eth = etif default_network
let main = main "App.Make" ~pos:__POS__ (ethernet @-> job)

let () =
  let ramdisk (conf : ipv4_config) =
    match conf with { network } -> ramdisk "secrets\f42"
  in
  register "etif" [ main $ eth ]
