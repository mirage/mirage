open Functoria
open Mirage_impl_time
open Mirage_impl_mclock

type random

val random : random typ
val rng : ?time:time impl -> ?mclock:mclock impl -> unit -> random impl
val default_random : random impl
