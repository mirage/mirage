open Mlnet.Types

type request
val init_request :
  clisockaddr:sockaddr ->
  srvsockaddr:sockaddr -> unit Lwt.u -> OS.Flow.t -> request Lwt.t
val meth : request -> Http_types.meth
val uri : request -> string
val path : request -> string
val body : request -> Http_message.contents list
val param :
  ?meth:[< `GET | `POST ] -> ?default:string -> request -> string -> string
val param_all : ?meth:Http_types.meth -> request -> string -> string list
val params : request -> (string, string) Hashtbl.t
val params_get : request -> (string * string) list
val params_post : request -> (string * string) list
val authorization : request -> [> `Basic of string * string ] option
val header : request -> name:string -> string list
val client_addr : request -> string
