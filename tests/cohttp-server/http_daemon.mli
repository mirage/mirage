open Cohttp
open Mlnet.Types

type conn_id
val string_of_conn_id : conn_id -> string

type daemon_spec = {
  address : string;
  auth : Http_types.auth_info;
  callback : conn_id -> Http_request.request -> string Lwt_stream.t Lwt.t;
  conn_closed : conn_id -> unit;
  port : int;
  root_dir : string option;
  exn_handler : exn -> unit Lwt.t;
  timeout : int option;
  auto_close : bool;
}
val respond :
  ?body:string ->
  ?headers:(string * string) list ->
  ?version:Cohttp.Http_types.version ->
  ?status:Cohttp.Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_control :
  string ->
  ?is_valid_status:(int -> bool) ->
  ?headers:(string * string) list ->
  ?body:string ->
  ?version:Cohttp.Http_types.version ->
  Cohttp.Http_types.status_code -> string Lwt_stream.t Lwt.t
val respond_redirect :
  location:string ->
  ?body:string ->
  ?version:Cohttp.Http_types.version ->
  ?status:Cohttp.Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_error :
  ?body:string ->
  ?version:Cohttp.Http_types.version ->
  ?status:Cohttp.Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
val respond_not_found :
  url:'a ->
  ?version:Cohttp.Http_types.version -> unit -> string Lwt_stream.t Lwt.t
val respond_forbidden :
  url:'a ->
  ?version:Cohttp.Http_types.version -> unit -> string Lwt_stream.t Lwt.t
val respond_unauthorized :
  ?version:'a -> ?realm:string -> unit -> string Lwt_stream.t Lwt.t
val respond_file :
	fname:string ->
  ?droot:string ->
  ?version:Cohttp.Http_types.version -> ?mime_type: string -> unit -> string Lwt_stream.t Lwt.t
val respond_with :
  Cohttp.Http_response.response -> string Lwt_stream.t Lwt.t
val daemon_callback :
  daemon_spec ->
  clisockaddr:sockaddr -> srvsockaddr:sockaddr -> Unix.IO.input_channel -> Unix.IO.output_channel -> unit Lwt.t
val main : daemon_spec -> 'a Lwt.t
module Trivial :
  sig
    val trivial_callback :
      conn_id -> Cohttp.Http_request.request -> string Lwt_stream.t Lwt.t
    val callback :
      conn_id -> Cohttp.Http_request.request -> string Lwt_stream.t Lwt.t
    val main : daemon_spec -> 'a Lwt.t
  end
val default_spec : daemon_spec
