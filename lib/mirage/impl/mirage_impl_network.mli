open Functoria

type network

val network : network typ
val netif : ?group:string -> string -> network impl
val default_network : network impl
val all_networks : string list ref
