open Functoria

val static_libs : string -> string list Action.t

val ldflags : string -> string list Action.t

val ldpostflags : string -> string list Action.t

val find_ld : string -> string Action.t

val link : Info.t -> string -> Mirage_key.mode -> bool -> string Action.t
