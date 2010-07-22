type r
val put_free_entry : r -> unit
val get_free_entry : unit -> r Lwt.t
val to_string: r -> string
val init : unit -> unit
