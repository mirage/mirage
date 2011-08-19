open Lwt

type t = unit
type id = string

let create t = fail (Failure "not implemented")
let plug t = fail (Failure "not implemented")
let unplug t = ()
let output t fn = fail (Failure "not implemented")
let enumerate () = return []
let listen t fn = fail (Failure "not implemented")
let mac t = ""
