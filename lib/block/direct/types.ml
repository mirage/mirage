module type RO = sig
  type t
  exception Error
  val create : Manager.interface -> t Lwt.t
  val iter_s : t -> (string -> unit Lwt.t) -> unit Lwt.t

  val size : t -> string -> int64 Lwt.t
  val read : t -> string -> Bitstring.t Lwt_stream.t Lwt.t
end
