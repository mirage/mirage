exception MalFormed

val width: int array
val next: string -> int -> int
val compute_len: string -> int -> int -> int
val blit_to_int: string -> int -> int array -> int -> int -> unit
val to_int_array: string -> int -> int -> int array

val store: Buffer.t -> int -> unit
val from_int_array: int array -> int -> int -> string

val from_stream: char Stream.t -> int
val stream_from_char_stream: char Stream.t -> int Stream.t
