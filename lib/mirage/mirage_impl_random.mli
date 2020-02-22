type random

val random : random Functoria.typ

val stdlib_random : random Functoria.impl

val default_random : random Functoria.impl

val nocrypto : Functoria.job Functoria.impl

val nocrypto_random : random Functoria.impl

val is_entropy_enabled : unit -> bool
