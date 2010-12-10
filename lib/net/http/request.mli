open Nettypes

type request
val init_request :
  clisockaddr:sockaddr ->
  srvsockaddr:sockaddr -> unit Lwt.u -> Flow.t -> request Lwt.t
val meth : request -> Types.meth
val uri : request -> string
val path : request -> string
val body : request -> Message.contents list
val param :
  ?meth:[< `GET | `POST ] -> ?default:string -> request -> string -> string
val param_all : ?meth:Types.meth -> request -> string -> string list
val params : request -> (string, string) Hashtbl.t
val params_get : request -> (string * string) list
val params_post : request -> (string * string) list
val authorization : request -> [> `Basic of string * string ] option
val header : request -> name:string -> string list
val client_addr : request -> string
