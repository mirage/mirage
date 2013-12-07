open Mirari_types.V1
open Lwt

let string_of_stream s =
  let s = List.map Cstruct.to_string s in
  return (String.concat "" s)

module Main (C: CONSOLE) (X: KV_RO) (Y: KV_RO) = struct

  let start c x y =
    let rec aux () =
      X.read x "a" 0 4096 >>= fun vx ->
      Y.read y "a" 0 4096 >>= fun vy ->
      begin match vx, vy with
      | `Ok sx, `Ok sy ->
        string_of_stream sx >>= fun sx ->
        string_of_stream sy >>= fun sy ->
        if sx = sy then C.log_s c "YES!"
        else C.log_s c "NO!"
      | _              -> C.log_s c "NO! NO!"
      end >>= fun () ->
      OS.Time.sleep 1. >>= fun () ->
      aux () in
    aux ()

  let stop c x y =
    return_unit

end
