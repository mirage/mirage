

module type IntTagSetModule =
sig
  type 'a elt

  type 'a t

  val empty : 'a t

  val is_empty : 'a t -> bool

  val mem : 'a elt -> 'a t -> bool

  val add : 'a elt -> 'a t -> 'a t

  val singleton : 'a elt -> 'a t

  val remove : 'a elt -> 'a t -> 'a t

  val union : 'a t -> 'a t -> 'a t

  val subset : 'a t -> 'a t -> bool

  val inter : 'a t -> 'a t -> 'a t

  val diff : 'a t -> 'a t -> 'a t

  val equal : 'a t -> 'a t -> bool

  val compare : 'a t -> 'a t -> int

  val elements : 'a t -> 'a elt list

  val choose : 'a t -> 'a elt

  val cardinal : 'a t -> int

  val iter : ('a elt -> unit) -> 'a t -> unit

  val fold : ('a elt -> 'b -> 'b) -> 'a t -> 'b -> 'b

  val for_all : ('a elt -> bool) -> 'a t -> bool

  val exists : ('a elt -> bool) -> 'a t -> bool

  val filter : ('a elt -> bool) -> 'a t -> 'a t

  val partition : ('a elt -> bool) -> 'a t -> 'a t * 'a t

end


module Make(O : sig type t val tag : t -> int end) :
  (IntTagSetModule with type 'a elt = O.t)
