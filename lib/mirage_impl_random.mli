open Functoria
open Mirage_impl_entry_points

type random

val random : random typ

val stdlib_random : entry_points impl -> random impl

val default_random : ?entry_points:entry_points impl -> unit -> random impl

val nocrypto_random : entry_points impl -> random impl

val is_entropy_enabled : unit -> bool
