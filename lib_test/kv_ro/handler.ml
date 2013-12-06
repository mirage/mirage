open V1

open Lwt

module Main (C: CONSOLE) (X: KV_RO) (Y: KV_RO) = struct

  let start c x y =
    let rec aux () =
      X.read x "a" >>= fun vx ->
      Y.read y "a" >>= fun vy ->
      begin match vx, vy with
      | `Ok sx, `Ok sy -> if sx = sy then C.log_s "YES!" else C.log_s "NO!"
      | _              -> C.log_s "NO! NO!"
      end >>= fun () ->
      Time.sleep 1. >>= fun () ->
      aux () in
    aux ()

  let stop c x y =
    return_unit

end
