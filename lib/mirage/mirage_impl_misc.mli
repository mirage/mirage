open Functoria

module Log : Logs.LOG

val get_target : Info.t -> Mirage_key.mode

val backend_predicate : Mirage_key.mode -> string

val connect_err : string -> int -> string

val pp_key : Format.formatter -> 'a Key.key -> unit

val query_ocamlfind :
  ?recursive:bool ->
  ?format:string ->
  ?predicates:string ->
  string list ->
  string list Action.t

val opam_prefix : string Action.t Lazy.t

val extra_c_artifacts : string -> string list -> string list Action.t

val terminal : unit -> bool
