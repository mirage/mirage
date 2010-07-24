type r
type perm = RO | RW
val put_free_entry : r -> unit
val get_free_entry : unit -> r Lwt.t
val grant_access : r -> int -> perm -> unit
val to_string : r -> string
