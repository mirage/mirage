type t

val v : ?bin:(Fpath.t * Fpath.t) list -> ?etc:Fpath.t list -> unit -> t

val union : t -> t -> t

val empty : t

val pp : t Fmt.t

val dump : t Fmt.t
