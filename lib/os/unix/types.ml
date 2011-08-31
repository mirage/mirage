module type BLKIF = sig
  type t
  type id = string

  val create : (id -> t -> unit Lwt.t) -> unit Lwt.t
  val destroy : t -> unit Lwt.t
  val read_page : t -> int64 -> Bitstring.t Lwt.t
  val sector_size: t -> int
end
