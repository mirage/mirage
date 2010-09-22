open Mlnet.Types

type response
val init :
  ?body:Http_message.contents list ->
  ?headers:(string * string) list ->
  ?version:Http_types.version ->
  ?status:Http_types.status_code ->
  ?reason:string ->
  ?clisockaddr:sockaddr ->
  ?srvsockaddr:sockaddr -> unit -> response
val version_string : response -> string
val code : response -> int
val set_code : response -> int -> unit
val status : response -> Http_types.status
val set_status : response -> Http_types.status -> unit
val reason : response -> string
val set_reason : response -> string -> unit
val status_line : response -> string
val is_informational : response -> bool
val is_success : response -> bool
val is_redirection : response -> bool
val is_client_error : response -> bool
val is_server_error : response -> bool
val is_error : response -> bool
val add_basic_headers : response -> unit
val content_type : response -> string option
val set_content_type : response -> value:string -> unit
val content_encoding : response -> string option
val set_content_encoding : response -> value:string -> unit
val date : response -> string option
val set_date : response -> value:string -> unit
val expires : response -> string option
val set_expires : response -> value:string -> unit
val server : response -> string option
val set_server : response -> value:string -> unit
val serialize :
  response ->
  'a -> ('a -> string -> unit Lwt.t) -> ('a -> string -> int -> int -> unit Lwt.t) ->
  unit Lwt.t
val serialize_to_output_channel : response -> Unix.IO.output_channel -> unit Lwt.t
val serialize_to_stream : response -> string Lwt_stream.t
