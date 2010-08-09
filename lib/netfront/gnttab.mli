type r
type perm = RO | RW
val put_free_entry : r -> unit
val get_free_entry : unit -> r Lwt.t
val grant_access : r -> int -> perm -> unit
val read : r -> int -> int -> string
val write : r -> string -> int -> int -> unit
val end_access : r -> unit
val gnttab_ref : r -> int
val to_string : r -> string
external release_page : r -> Hw_page.t = "caml_gnt_release_page"
