open Functoria

val get_target : Info.t -> Mirage_key.mode
val connect_err : string -> int -> string
val pp_key : Format.formatter -> 'a Mirage_runtime_key.key -> unit
val terminal : unit -> bool
