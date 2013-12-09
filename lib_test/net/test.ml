open Mirage_types.V1
open Lwt

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

module Sender (C: CONSOLE) (N: NETWORK) = struct

  let debug c fmt =
    Printf.kprintf (fun str ->
        C.log_s c (yellow "SENDER   %s\n%!" str)
      ) fmt

  let start c net =
    debug c "Hi!" >>= fun () ->
    let rec aux i =
      let frame = "Frame " ^ string_of_int i in
      debug c "Sending '%s'!" frame >>= fun () ->
      N.write net (Cstruct.of_string frame) >>= fun () ->
      OS.Time.sleep 1. >>= fun () ->
      aux (i+1) in
    aux 1

end

module Receiver (C: CONSOLE) (N: NETWORK) = struct

  let debug c fmt =
    Printf.kprintf (fun str ->
        C.log_s c (green "RECV   %s\n%!" str)
      ) fmt

  let start c net =
    debug c "Hi!" >>= fun () ->
    N.listen net (fun page ->
        let s = Cstruct.to_string page in
        debug c "Got '%s'" s
      ) >>= function
    | `Error _ -> debug c "Netif.error!"
    | `Ok ()   -> return_unit

end
