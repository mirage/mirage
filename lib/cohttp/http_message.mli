open Mlnet.Types

type contents =
    [ `Buffer of Buffer.t
    | `String of string
    | `Inchan of int64 * Unix.IO.input_channel * unit Lwt.u
    ]
type message
val body : message -> contents list
val body_size : contents list -> int64
val string_of_body : contents list -> string Lwt.t
val set_body : message -> contents -> unit
val add_body : message -> contents -> unit
val add_header : message -> name:string -> value:string -> unit
val add_headers : message -> (string * string) list -> unit
val replace_header : message -> name:string -> value:string -> unit
val replace_headers : message -> (string * string) list -> unit
val remove_header : message -> name:string -> unit
val has_header : message -> name:string -> bool
val header : message -> name:string -> string list
val headers : message -> (string * string) list
val client_addr : message -> string
val server_addr : message -> string
val client_port : message -> int
val server_port : message -> int
val version : message -> Http_types.version
val init :
  body:contents list ->
  headers:(string * string) list ->
  version:Http_types.version ->
  clisockaddr:sockaddr -> srvsockaddr:sockaddr -> message
val serialize :
  message ->
  'a -> ('a -> string -> unit Lwt.t) -> ('a -> string -> int -> int -> unit Lwt.t) ->
  fstLineToString:string -> unit Lwt.t
val serialize_to_output_channel :
  message -> Unix.IO.output_channel -> fstLineToString:string -> unit Lwt.t
val serialize_to_stream :
  message -> fstLineToString:string -> string Lwt_stream.t
