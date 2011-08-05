
open Hashcons

type 'a t

val empty : 'a t

val is_empty : 'a t -> bool

val mem : 'a hash_consed -> 'a t -> bool

val add : 'a hash_consed -> 'a t -> 'a t

val singleton : 'a hash_consed -> 'a t

val remove : 'a hash_consed -> 'a t -> 'a t

val union : 'a t -> 'a t -> 'a t

val subset : 'a t -> 'a t -> bool

val inter : 'a t -> 'a t -> 'a t

val diff : 'a t -> 'a t -> 'a t

val equal : 'a t -> 'a t -> bool

val equalq : 'a t -> 'a t -> bool

val compare : 'a t -> 'a t -> int

val elements : 'a t -> 'a hash_consed list

val choose : 'a t -> 'a  hash_consed

val cardinal : 'a t -> int

val iter : ('a hash_consed -> unit) -> 'a t -> unit

val fold : ('a hash_consed -> 'b -> 'b) -> 'a t -> 'b -> 'b

val for_all : ('a hash_consed -> bool) -> 'a t -> bool

val exists : ('a hash_consed -> bool) -> 'a t -> bool

val filter : ('a hash_consed -> bool) -> 'a t -> 'a t

val partition : ('a hash_consed -> bool) -> 'a t -> 'a t * 'a t

