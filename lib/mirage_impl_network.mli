type network

val network : network Functoria.typ

val netif : ?group:string -> string -> network Functoria.impl

val default_network : network Functoria.impl

val all_networks : string list ref
