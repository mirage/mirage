open Functoria

val get_target : Info.t -> Mirage_key.mode
val connect_err : string -> ?max:int -> int -> 'a
val terminal : unit -> bool
val pp_opt : string -> string option Fmt.t
val pp_label : string -> string option Fmt.t

val pop :
  err:(unit -> string option * string list) ->
  'b option ->
  string list ->
  string option * string list

val pop_and_check_empty :
  err:(unit -> string option * string list) ->
  'b option ->
  string list ->
  string option

module K : sig
  type t = [] | ( :: ) : 'a Runtime_arg.arg option * t -> t
end

val runtime_args_opt : K.t -> Runtime_arg.t list
