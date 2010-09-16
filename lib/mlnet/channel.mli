open Types

type t

type sockaddr = 
  | TCP of ipv4_addr * int
  | UDP of ipv4_addr * int

val read: t -> string -> int -> int -> int Lwt.t
val write: t -> string -> int -> int -> int Lwt.t

val connect: sockaddr -> t Lwt.t

val close: t -> unit
