open Types

type t

type 'a resp =
  | OK of 'a
  | Err of string
  | Retry

type sockaddr = 
  | TCP of ipv4_addr * int
  | UDP of ipv4_addr * int

val read: t -> string -> int -> int -> int resp Lwt.t
val write: t -> string -> int -> int -> int resp Lwt.t

val connect: sockaddr -> t resp Lwt.t
val listen: (t -> unit Lwt.t) -> sockaddr -> unit Lwt.t
val close: t -> unit
