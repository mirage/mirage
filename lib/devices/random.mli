open Functoria
open Time
open Mclock

type random

val random : random typ
val rng : ?time:time impl -> ?mclock:mclock impl -> unit -> random impl
val default_random : random impl
