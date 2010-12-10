open Nettypes

type conn_id
val string_of_conn_id : conn_id -> string

type daemon_spec = {
  address : string;
  auth : Types.auth_info;
  callback : conn_id -> Request.request -> string Lwt_stream.t Lwt.t;
  conn_closed : conn_id -> unit;
  port : int;
  exn_handler : exn -> unit Lwt.t;
  timeout : float option;
}
val respond :
  ?body:string ->
  ?headers:(string * string) list ->
  ?version:Types.version ->
  ?status:Types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_control :
  string ->
  ?is_valid_status:(int -> bool) ->
  ?headers:(string * string) list ->
  ?body:string ->
  ?version:Types.version ->
  Types.status_code -> string Lwt_stream.t Lwt.t
val respond_redirect :
  location:string ->
  ?body:string ->
  ?version:Types.version ->
  ?status:Types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_error :
  ?body:string ->
  ?version:Types.version ->
  ?status:Types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_not_found :
  url:'a ->
  ?version:Types.version -> unit -> string Lwt_stream.t Lwt.t
val respond_forbidden :
  url:'a ->
  ?version:Types.version -> unit -> string Lwt_stream.t Lwt.t
val respond_unauthorized :
  ?version:'a -> ?realm:string -> unit -> string Lwt_stream.t Lwt.t
val respond_with :
  Response.response -> string Lwt_stream.t Lwt.t
val daemon_callback :
  daemon_spec ->
  clisockaddr:sockaddr -> srvsockaddr:sockaddr -> Flow.t -> unit Lwt.t
val main : daemon_spec -> unit Lwt.t
