open Types

type t

val read: t -> string -> int -> int -> int resp Lwt.t
val write: t -> string -> int -> int -> int resp Lwt.t

val connect: sockaddr -> t resp Lwt.t
val listen: (t -> unit Lwt.t) -> sockaddr -> unit Lwt.t
val close: t -> unit
