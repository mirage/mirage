
module type IntTagMapModule =
sig
  type 'a key

  type ('a,'data) t

  val empty : ('a,'data) t

  val add : 'a key -> 'data -> ('a,'data) t -> ('a,'data) t

  val find : 'a key -> ('a,'data) t -> 'data

  val remove : 'a key -> ('a,'data) t -> ('a,'data) t

  val mem :  'a key -> ('a,'data) t -> bool

  val iter : ('a key -> 'data -> unit) -> ('a,'data) t -> unit

  val map : ('data1 -> 'data2) -> ('a,'data1) t -> ('a,'data2) t

  val fold : ('a key -> 'data -> 'accu -> 'accu) -> ('a,'data) t -> 'accu -> 'accu

  val size :  ('a,'data) t -> int

  val elements :  ('a,'data) t -> ('a key * 'data) list
end

module Make(O : sig type t val tag : t -> int end) :
  (IntTagMapModule with type 'a key = O.t)
