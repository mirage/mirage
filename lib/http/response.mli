open Nettypes

type response
val init :
  ?body:Message.contents list ->
  ?headers:(string * string) list ->
  ?version:Types.version ->
  ?status:Types.status_code ->
  ?reason:string ->
  unit -> response
val version_string : response -> string
val code : response -> int
val set_code : response -> int -> unit
val status : response -> Types.status
val set_status : response -> Types.status -> unit
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
val serialize_to_stream : response -> string Lwt_stream.t
