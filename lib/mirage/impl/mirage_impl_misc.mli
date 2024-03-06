open Functoria

val get_target : Info.t -> Mirage_key.mode
val connect_err : string -> int -> string
val pp_key : Format.formatter -> 'a Mirage_runtime_arg.arg -> unit
val terminal : unit -> bool
