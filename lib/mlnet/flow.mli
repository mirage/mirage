open Types

type t

val read: t -> string -> int -> int -> int Lwt.t
val read_line: t -> string Lwt.t
val read_all: t -> string Lwt.t

val write: t -> string -> int -> int -> int Lwt.t
val write_all: t -> string -> unit Lwt.t

val connect: sockaddr -> t Lwt.t
val with_connection: sockaddr -> (t -> 'a Lwt.t) -> 'a Lwt.t

val listen: (sockaddr -> t -> unit Lwt.t) -> sockaddr -> unit Lwt.t
val close: t -> unit
