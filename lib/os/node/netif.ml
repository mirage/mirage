open Lwt

type t = unit
type id = string
type interface = unit

let create id = fail (Failure "not implemented")
let listen t fn = fail (Failure "not implemented")
let destroy t = fail (Failure "not implemented")
let output t fn = fail (Failure "not implemented")
let enumerate () = return []
let mac t = ""
let string_of_id id = id
