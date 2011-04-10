type regexp

val chars: Cset.t -> regexp
val seq: regexp -> regexp -> regexp
val alt: regexp -> regexp -> regexp
val rep: regexp -> regexp
val plus: regexp -> regexp
val eps: regexp

val compile: regexp array -> (int * int array * bool array) array
val partitions: unit -> (int * (int * int * int) list) list
