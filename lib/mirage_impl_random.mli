open Functoria.DSL

type random

val random : random typ

val stdlib_random : random impl

val default_random : random impl

val nocrypto : job impl

val nocrypto_random : random impl

val is_entropy_enabled : unit -> bool
