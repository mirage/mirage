open Functoria
open Mclock

type random

val random : random typ
val rng : ?mclock:mclock impl -> unit -> random impl
val default_random : random impl
