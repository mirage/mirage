open Key
open Functoria

val get_target : Info.t -> mode
val connect_err : string -> ?max:int -> int -> 'a
val terminal : unit -> bool
val pp_label : string -> string option Fmt.t

val pop :
  err:(unit -> string option * string list) ->
  'b option ->
  string list ->
  string option * string list
