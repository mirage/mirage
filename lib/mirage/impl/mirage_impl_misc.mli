open Functoria

val get_target : Info.t -> Mirage_key.mode
val connect_err : string -> int -> 'a
val terminal : unit -> bool
val pp_key : 'a Mirage_runtime_arg.arg Fmt.t
val pp_opt : string -> 'a Mirage_runtime_arg.arg option Fmt.t
val pp_label : string -> 'a Mirage_runtime_arg.arg option Fmt.t

module K : sig
  type t = [] | ( :: ) : 'a Runtime_arg.arg option * t -> t
end

val runtime_args_opt : K.t -> Runtime_arg.t list
