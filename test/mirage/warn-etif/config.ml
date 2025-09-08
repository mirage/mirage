open Mirage

(* This file exercises as many warnings as possible. It is thus a very poor
   example of a config.ml file. *)

module T : sig end = struct
  type t = ()
  type t' = ()
end

let rec eth = etif default_network
let main = main "App.Make" ~pos:__POS__ (ethernet @-> job)

type ipv4_config = {
  network : Ipaddr.V4.Prefix.t;
  gateway : Ipaddr.V4.t option;
}

let () =
  let ramdisk (conf : ipv4_config) =
    match conf with { network } -> ramdisk "secrets\f42"
  in
  register "etif" [ main $ eth ]
