type conn_id
val string_of_conn_id : conn_id -> string

type daemon_spec = {
  address : string;
  auth : Types.auth_info;
  callback : conn_id -> Net.Flow.ipv4_src -> Net.Flow.ipv4_dst ->
    Request.request -> string Lwt_stream.t Lwt.t;
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
  daemon_spec -> Net.Flow.ipv4_src -> Net.Flow.ipv4_dst -> Net.Channel.TCPv4.t -> unit Lwt.t

val main : Net.Flow.TCPv4.mgr -> Net.Flow.TCPv4.src -> daemon_spec -> unit Lwt.t
