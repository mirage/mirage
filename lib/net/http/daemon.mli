open Nettypes

type conn_id
val string_of_conn_id : conn_id -> string

type daemon_spec = {
  address : string;
  auth : Http_types.auth_info;
  callback : conn_id -> Http_request.request -> string Lwt_stream.t Lwt.t;
  conn_closed : conn_id -> unit;
  port : int;
  exn_handler : exn -> unit Lwt.t;
  timeout : float option;
}
val respond :
  ?body:string ->
  ?headers:(string * string) list ->
  ?version:Http_types.version ->
  ?status:Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_control :
  string ->
  ?is_valid_status:(int -> bool) ->
  ?headers:(string * string) list ->
  ?body:string ->
  ?version:Http_types.version ->
  Http_types.status_code -> string Lwt_stream.t Lwt.t
val respond_redirect :
  location:string ->
  ?body:string ->
  ?version:Http_types.version ->
  ?status:Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_error :
  ?body:string ->
  ?version:Http_types.version ->
  ?status:Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_not_found :
  url:'a ->
  ?version:Http_types.version -> unit -> string Lwt_stream.t Lwt.t
val respond_forbidden :
  url:'a ->
  ?version:Http_types.version -> unit -> string Lwt_stream.t Lwt.t
val respond_unauthorized :
  ?version:'a -> ?realm:string -> unit -> string Lwt_stream.t Lwt.t
val respond_with :
  Http_response.response -> string Lwt_stream.t Lwt.t
val daemon_callback :
  daemon_spec ->
  clisockaddr:sockaddr -> srvsockaddr:sockaddr -> Flow.t -> unit Lwt.t
val main : daemon_spec -> unit Lwt.t
