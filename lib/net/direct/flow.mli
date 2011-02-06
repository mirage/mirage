open Nettypes

module TCPv4 : sig
  type t
  type mgr = Manager.t
  type src = ipv4_addr option * int  
  type dst = ipv4_addr * int

  val read : t -> OS.Istring.View.t option Lwt.t
  val write : t -> OS.Istring.View.t -> unit Lwt.t
  val close : t -> unit Lwt.t

  val listen : mgr -> src -> (dst -> t -> unit Lwt.t) -> unit Lwt.t
  val connect : mgr -> src -> dst -> (t -> unit Lwt.t) -> unit Lwt.t
end
