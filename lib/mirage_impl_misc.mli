open Rresult

module Log : Logs.LOG

val get_target : Functoria.Info.t -> Mirage_key.mode
val backend_predicate : Mirage_key.mode -> string

val connect_err : string -> int -> string

val with_output :
     ?mode:int
  -> Fpath.t
  -> (out_channel -> unit -> ('a, ([> Rresult.R.msg] as 'b)) result)
  -> string
  -> ('a, 'b) result

val pp_key : Format.formatter -> 'a Functoria.Key.key -> unit

val query_ocamlfind :
     ?recursive:bool
  -> ?format:string
  -> ?predicates:string
  -> string list
  -> (string list, [> Rresult.R.msg]) result

val opam_prefix : (string, [> R.msg ]) result Lazy.t
val pkg_config : string -> string list -> (string list, [> R.msg ]) result
val extra_c_artifacts : string -> string list -> (string list, [> R.msg ]) result

val terminal : unit -> bool

val rr_iter : ('a -> (unit, 'e) result) -> 'a list -> (unit, 'e) result
