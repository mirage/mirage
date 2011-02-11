type time =
    [ `Day of int | `Hour of int | `Minute of int | `Second of int ] list
type expiration = [ `Age of time | `Discard | `Session | `Until of float ]
type cookie

val make :
  ?expiry:expiration ->
  ?path:string ->
  ?domain:string -> ?secure:bool -> string -> string -> string * cookie
val serialize :
  ?version:[ `HTTP_1_0 | `HTTP_1_1 ] ->
  string * cookie -> string * string
val extract : Request.request -> (string * string) list
