module Log : Logs.LOG

val get_target : Functoria.Info.t -> Mirage_key.mode

val connect_err : string -> int -> string

val with_output :
     ?mode:int
  -> Fpath.t
  -> (out_channel -> unit -> ('a, ([> Rresult.R.msg] as 'b)) result)
  -> string
  -> ('a, 'b) result

val pp_key : Format.formatter -> 'a Functoria_key.key -> unit

val query_ocamlfind :
     ?recursive:bool
  -> ?format:string
  -> ?predicates:string
  -> string list
  -> (string list, [> Rresult.R.msg]) result
