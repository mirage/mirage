
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


module MakePoly(O : sig type 'a t val tag : 'a t -> int end) =
struct
  type 'a key = 'a O.t

  type ('a,'data) t =
    | Empty
    | Leaf of 'a key * 'data
    | Branch of int * int * ('a,'data) t * ('a,'data) t

  let empty = Empty

  let zero_bit k m = (k land m) = 0

  let rec tag_mem k = function
    | Empty -> false
    | Leaf (j,_) -> k = O.tag j
    | Branch (_, m, l, r) -> tag_mem k (if zero_bit k m then l else r)

  let mem e s = tag_mem (O.tag e) s

  let rec tag_find k = function
    | Empty -> raise Not_found
    | Leaf (j,x) -> if k = O.tag j then x else raise Not_found
    | Branch (_, m, l, r) -> tag_find k (if zero_bit k m then l else r)

  let find e s = tag_find (O.tag e) s

  let lowest_bit x = x land (-x)

  let branching_bit p0 p1 = lowest_bit (p0 lxor p1)

  let mask p m = p land (m-1)

  let join p0 t0 p1 t1 =
    let m = branching_bit p0 p1 in
    if zero_bit p0 m then
      Branch (mask p0 m, m, t0, t1)
    else
      Branch (mask p0 m, m, t1, t0)

  let match_prefix k p m = (mask k m) = p

  let rec ins e e_tag x t =
    match t with
      | Empty -> Leaf (e,x)
      | Leaf(j,_) ->
      let j_tag = O.tag j in
      if j_tag = e_tag then Leaf (e,x) else join e_tag (Leaf(e,x)) j_tag t
      | Branch(p,m,t0,t1) ->
      if match_prefix e_tag p m
      then
        if zero_bit e_tag m
        then Branch(p, m, ins e e_tag x t0, t1)
        else Branch(p, m, t0, ins e e_tag x t1)
      else
        join e_tag (Leaf(e,x)) p t

  let add e x t = ins e (O.tag e) x t

  let branch p m t0 t1 =
    if t0=Empty
    then t1
    else
      if t1=Empty
      then t0
      else Branch(p,m,t0,t1)

    let rec rmv e_tag t =
      match t with
    | Empty -> Empty
    | Leaf(j,_) -> if e_tag = O.tag j then Empty else t
    | Branch(p,m,t0,t1) ->
        if match_prefix e_tag p m
        then
          if zero_bit e_tag m
          then branch p m (rmv e_tag t0) t1
          else branch p m t0 (rmv e_tag t1)
        else t

    let remove k t = rmv (O.tag k) t

    let rec iter f = function
      | Empty -> ()
      | Leaf(k,x) -> f k x
      | Branch(_,_,t0,t1) -> iter f t0; iter f t1

    let rec map f = function
      | Empty -> Empty
      | Leaf(k,x) -> Leaf(k, f x)
      | Branch(p,m,t0,t1) -> Branch(p, m, map f t0, map f t1)

        (*
          let rec mapi f = function
          | Empty -> Empty
          | Leaf (k,x) -> Leaf (k, f k x)
          | Branch (p,m,t0,t1) -> Branch (p, m, mapi f t0, mapi f t1)
        *)

    let rec fold f s accu = match s with
      | Empty -> accu
      | Leaf(k,x) -> f k x accu
      | Branch(_,_,t0,t1) -> fold f t0 (fold f t1 accu)

    let rec size t =
      match t with
      | Empty -> 0
      | Leaf(k,x) -> 1
      | Branch(_,_,t0,t1) -> size t0 + size t1

  let elements s =
    let rec elements_aux acc = function
      | Empty -> acc
      | Leaf(k,x) -> (k,x) :: acc
      | Branch (_,_,t0,t1) -> elements_aux (elements_aux acc t0) t1
    in
    elements_aux [] s


end


module Make(O : sig type t val tag : t -> int end) =
  MakePoly(struct type 'a t = O.t let tag = O.tag end)

