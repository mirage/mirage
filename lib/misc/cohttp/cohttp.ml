(* This file has been auto-generated using ocamlpack and includes:
      http_types.mli
      http_types.ml
      http_constants.mli
      http_constants.ml
      http_misc.mli
      http_misc.ml
      base64.mli
      base64.ml
      http_url.mli
      http_url.ml
      http_common.mli
      http_common.ml
      http_parser_sanity.mli
      http_parser_sanity.ml
      http_parser.mli
      http_parser.ml
      http_user_agent.mli
      http_user_agent.ml
      http_message.mli
      http_message.ml
      http_response.mli
      http_response.ml
      http_request.mli
      http_request.ml
      http_cookie.mli
      http_cookie.ml
      http_daemon.mli
      http_daemon.ml
 *)

module Http_types : sig
# 1 "cohttp/http_types.mli"

# 2 "cohttp/http_types.mli"
(*
# 3 "cohttp/http_types.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_types.mli"

# 5 "cohttp/http_types.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_types.mli"

# 7 "cohttp/http_types.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_types.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_types.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_types.mli"

# 11 "cohttp/http_types.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_types.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_types.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_types.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_types.mli"

# 16 "cohttp/http_types.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_types.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_types.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_types.mli"
  USA
# 20 "cohttp/http_types.mli"
*)
# 21 "cohttp/http_types.mli"

# 22 "cohttp/http_types.mli"
(** Type definitions *)
# 23 "cohttp/http_types.mli"

# 24 "cohttp/http_types.mli"
  (** HTTP version, actually only 1.0 and 1.1 are supported. Note that
# 25 "cohttp/http_types.mli"
  'supported' here means only 'accepted inside a HTTP request line', no
# 26 "cohttp/http_types.mli"
  different behaviours are actually implemented depending on HTTP version *)
# 27 "cohttp/http_types.mli"
type version =
# 28 "cohttp/http_types.mli"
  [ `HTTP_1_0
# 29 "cohttp/http_types.mli"
  | `HTTP_1_1
# 30 "cohttp/http_types.mli"
  ]
# 31 "cohttp/http_types.mli"

# 32 "cohttp/http_types.mli"
  (** HTTP method, actually only GET and POST methods are supported *)
# 33 "cohttp/http_types.mli"
type meth =
# 34 "cohttp/http_types.mli"
  [ `GET
# 35 "cohttp/http_types.mli"
  | `POST
# 36 "cohttp/http_types.mli"
  | `HEAD
# 37 "cohttp/http_types.mli"
  | `DELETE
# 38 "cohttp/http_types.mli"
  ]
# 39 "cohttp/http_types.mli"

# 40 "cohttp/http_types.mli"
  (** authentication information *)
# 41 "cohttp/http_types.mli"
type auth_info =
# 42 "cohttp/http_types.mli"
  [ `None
# 43 "cohttp/http_types.mli"
  | `Basic of string * (string -> string -> bool) (* realm, user -> pass -> bool *)
# 44 "cohttp/http_types.mli"
(*| `Digest of ...  (* TODO digest authentication *) *)
# 45 "cohttp/http_types.mli"
  ]
# 46 "cohttp/http_types.mli"

# 47 "cohttp/http_types.mli"
  (** @see "RFC2616" informational HTTP status *)
# 48 "cohttp/http_types.mli"
type informational_status =
# 49 "cohttp/http_types.mli"
  [ `Continue
# 50 "cohttp/http_types.mli"
  | `Switching_protocols
# 51 "cohttp/http_types.mli"
  ]
# 52 "cohttp/http_types.mli"

# 53 "cohttp/http_types.mli"
  (** @see "RFC2616" success HTTP status *)
# 54 "cohttp/http_types.mli"
type success_status =
# 55 "cohttp/http_types.mli"
  [ `OK
# 56 "cohttp/http_types.mli"
  | `Created
# 57 "cohttp/http_types.mli"
  | `Accepted
# 58 "cohttp/http_types.mli"
  | `Non_authoritative_information
# 59 "cohttp/http_types.mli"
  | `No_content
# 60 "cohttp/http_types.mli"
  | `Reset_content
# 61 "cohttp/http_types.mli"
  | `Partial_content
# 62 "cohttp/http_types.mli"
  ]
# 63 "cohttp/http_types.mli"

# 64 "cohttp/http_types.mli"
  (** @see "RFC2616" redirection HTTP status *)
# 65 "cohttp/http_types.mli"
type redirection_status =
# 66 "cohttp/http_types.mli"
  [ `Multiple_choices
# 67 "cohttp/http_types.mli"
  | `Moved_permanently
# 68 "cohttp/http_types.mli"
  | `Found
# 69 "cohttp/http_types.mli"
  | `See_other
# 70 "cohttp/http_types.mli"
  | `Not_modified
# 71 "cohttp/http_types.mli"
  | `Use_proxy
# 72 "cohttp/http_types.mli"
  | `Temporary_redirect
# 73 "cohttp/http_types.mli"
  ]
# 74 "cohttp/http_types.mli"

# 75 "cohttp/http_types.mli"
  (** @see "RFC2616" client error HTTP status *)
# 76 "cohttp/http_types.mli"
type client_error_status =
# 77 "cohttp/http_types.mli"
  [ `Bad_request
# 78 "cohttp/http_types.mli"
  | `Unauthorized
# 79 "cohttp/http_types.mli"
  | `Payment_required
# 80 "cohttp/http_types.mli"
  | `Forbidden
# 81 "cohttp/http_types.mli"
  | `Not_found
# 82 "cohttp/http_types.mli"
  | `Method_not_allowed
# 83 "cohttp/http_types.mli"
  | `Not_acceptable
# 84 "cohttp/http_types.mli"
  | `Proxy_authentication_required
# 85 "cohttp/http_types.mli"
  | `Request_time_out
# 86 "cohttp/http_types.mli"
  | `Conflict
# 87 "cohttp/http_types.mli"
  | `Gone
# 88 "cohttp/http_types.mli"
  | `Length_required
# 89 "cohttp/http_types.mli"
  | `Precondition_failed
# 90 "cohttp/http_types.mli"
  | `Request_entity_too_large
# 91 "cohttp/http_types.mli"
  | `Request_URI_too_large
# 92 "cohttp/http_types.mli"
  | `Unsupported_media_type
# 93 "cohttp/http_types.mli"
  | `Requested_range_not_satisfiable
# 94 "cohttp/http_types.mli"
  | `Expectation_failed
# 95 "cohttp/http_types.mli"
  ]
# 96 "cohttp/http_types.mli"

# 97 "cohttp/http_types.mli"
  (** @see "RFC2616" server error HTTP status *)
# 98 "cohttp/http_types.mli"
type server_error_status =
# 99 "cohttp/http_types.mli"
  [ `Internal_server_error
# 100 "cohttp/http_types.mli"
  | `Not_implemented
# 101 "cohttp/http_types.mli"
  | `Bad_gateway
# 102 "cohttp/http_types.mli"
  | `Service_unavailable
# 103 "cohttp/http_types.mli"
  | `Gateway_time_out
# 104 "cohttp/http_types.mli"
  | `HTTP_version_not_supported
# 105 "cohttp/http_types.mli"
  ]
# 106 "cohttp/http_types.mli"

# 107 "cohttp/http_types.mli"
type error_status =
# 108 "cohttp/http_types.mli"
  [ client_error_status
# 109 "cohttp/http_types.mli"
  | server_error_status
# 110 "cohttp/http_types.mli"
  ]
# 111 "cohttp/http_types.mli"

# 112 "cohttp/http_types.mli"
  (** HTTP status *)
# 113 "cohttp/http_types.mli"
type status =
# 114 "cohttp/http_types.mli"
  [ informational_status
# 115 "cohttp/http_types.mli"
  | success_status
# 116 "cohttp/http_types.mli"
  | redirection_status
# 117 "cohttp/http_types.mli"
  | client_error_status
# 118 "cohttp/http_types.mli"
  | server_error_status
# 119 "cohttp/http_types.mli"
  ]
# 120 "cohttp/http_types.mli"

# 121 "cohttp/http_types.mli"
type status_code = [ `Code of int | status ]
# 122 "cohttp/http_types.mli"

# 123 "cohttp/http_types.mli"
  (** {2 Exceptions} *)
# 124 "cohttp/http_types.mli"

# 125 "cohttp/http_types.mli"
  (** invalid header encountered *)
# 126 "cohttp/http_types.mli"
exception Invalid_header of string
# 127 "cohttp/http_types.mli"

# 128 "cohttp/http_types.mli"
  (** invalid header name encountered *)
# 129 "cohttp/http_types.mli"
exception Invalid_header_name of string
# 130 "cohttp/http_types.mli"

# 131 "cohttp/http_types.mli"
  (** invalid header value encountered *)
# 132 "cohttp/http_types.mli"
exception Invalid_header_value of string
# 133 "cohttp/http_types.mli"

# 134 "cohttp/http_types.mli"
  (** unsupported or invalid HTTP version encountered *)
# 135 "cohttp/http_types.mli"
exception Invalid_HTTP_version of string
# 136 "cohttp/http_types.mli"

# 137 "cohttp/http_types.mli"
  (** unsupported or invalid HTTP method encountered *)
# 138 "cohttp/http_types.mli"
exception Invalid_HTTP_method of string
# 139 "cohttp/http_types.mli"

# 140 "cohttp/http_types.mli"
  (** invalid HTTP status code integer representation encountered *)
# 141 "cohttp/http_types.mli"
exception Invalid_code of int
# 142 "cohttp/http_types.mli"

# 143 "cohttp/http_types.mli"
  (** invalid URL encountered *)
# 144 "cohttp/http_types.mli"
exception Malformed_URL of string
# 145 "cohttp/http_types.mli"

# 146 "cohttp/http_types.mli"
  (** invalid query string encountered *)
# 147 "cohttp/http_types.mli"
exception Malformed_query of string
# 148 "cohttp/http_types.mli"

# 149 "cohttp/http_types.mli"
  (** invalid query string part encountered, arguments are parameter name and
# 150 "cohttp/http_types.mli"
  parameter value *)
# 151 "cohttp/http_types.mli"
exception Malformed_query_part of string * string
# 152 "cohttp/http_types.mli"

# 153 "cohttp/http_types.mli"
  (** invalid request URI encountered *)
# 154 "cohttp/http_types.mli"
exception Malformed_request_URI of string
# 155 "cohttp/http_types.mli"

# 156 "cohttp/http_types.mli"
  (** malformed request received *)
# 157 "cohttp/http_types.mli"
exception Malformed_request of string
# 158 "cohttp/http_types.mli"

# 159 "cohttp/http_types.mli"
  (** malformed response received, argument is response's first line *)
# 160 "cohttp/http_types.mli"
exception Malformed_response of string
# 161 "cohttp/http_types.mli"

# 162 "cohttp/http_types.mli"
  (** a parameter you were looking for was not found *)
# 163 "cohttp/http_types.mli"
exception Param_not_found of string
# 164 "cohttp/http_types.mli"

# 165 "cohttp/http_types.mli"
  (** invalid HTTP status line encountered *)
# 166 "cohttp/http_types.mli"
exception Invalid_status_line of string
# 167 "cohttp/http_types.mli"

# 168 "cohttp/http_types.mli"
  (** an header you were looking for was not found *)
# 169 "cohttp/http_types.mli"
exception Header_not_found of string
# 170 "cohttp/http_types.mli"

# 171 "cohttp/http_types.mli"
  (** raisable by callbacks to force a 401 (unauthorized) HTTP answer.
# 172 "cohttp/http_types.mli"
      This exception should be raised _before_ sending any data over given out
# 173 "cohttp/http_types.mli"
      channel.
# 174 "cohttp/http_types.mli"
      @param realm authentication realm (usually needed to prompt user) *)
# 175 "cohttp/http_types.mli"
exception Unauthorized of string
# 176 "cohttp/http_types.mli"
end = struct
# 1 "cohttp/http_types.ml"

# 2 "cohttp/http_types.ml"
(*
# 3 "cohttp/http_types.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_types.ml"

# 5 "cohttp/http_types.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_types.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 7 "cohttp/http_types.ml"

# 8 "cohttp/http_types.ml"
  This program is free software; you can redistribute it and/or modify
# 9 "cohttp/http_types.ml"
  it under the terms of the GNU Library General Public License as
# 10 "cohttp/http_types.ml"
  published by the Free Software Foundation, version 2.
# 11 "cohttp/http_types.ml"

# 12 "cohttp/http_types.ml"
  This program is distributed in the hope that it will be useful,
# 13 "cohttp/http_types.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 14 "cohttp/http_types.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 15 "cohttp/http_types.ml"
  GNU Library General Public License for more details.
# 16 "cohttp/http_types.ml"

# 17 "cohttp/http_types.ml"
  You should have received a copy of the GNU Library General Public
# 18 "cohttp/http_types.ml"
  License along with this program; if not, write to the Free Software
# 19 "cohttp/http_types.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 20 "cohttp/http_types.ml"
  USA
# 21 "cohttp/http_types.ml"
*)
# 22 "cohttp/http_types.ml"

# 23 "cohttp/http_types.ml"
(** Type definitions *)
# 24 "cohttp/http_types.ml"

# 25 "cohttp/http_types.ml"
type version = [ `HTTP_1_0 | `HTTP_1_1 ]
# 26 "cohttp/http_types.ml"
type meth = [ `GET | `POST | `HEAD | `DELETE ]
# 27 "cohttp/http_types.ml"

# 28 "cohttp/http_types.ml"
type auth_info =
# 29 "cohttp/http_types.ml"
  [ `None
# 30 "cohttp/http_types.ml"
  | `Basic of string * (string -> string -> bool) (* realm, user -> pass -> bool *)
# 31 "cohttp/http_types.ml"
  ]
# 32 "cohttp/http_types.ml"

# 33 "cohttp/http_types.ml"
type informational_status =
# 34 "cohttp/http_types.ml"
  [ `Continue
# 35 "cohttp/http_types.ml"
  | `Switching_protocols
# 36 "cohttp/http_types.ml"
  ]
# 37 "cohttp/http_types.ml"
type success_status =
# 38 "cohttp/http_types.ml"
  [ `OK
# 39 "cohttp/http_types.ml"
  | `Created
# 40 "cohttp/http_types.ml"
  | `Accepted
# 41 "cohttp/http_types.ml"
  | `Non_authoritative_information
# 42 "cohttp/http_types.ml"
  | `No_content
# 43 "cohttp/http_types.ml"
  | `Reset_content
# 44 "cohttp/http_types.ml"
  | `Partial_content
# 45 "cohttp/http_types.ml"
  ]
# 46 "cohttp/http_types.ml"
type redirection_status =
# 47 "cohttp/http_types.ml"
  [ `Multiple_choices
# 48 "cohttp/http_types.ml"
  | `Moved_permanently
# 49 "cohttp/http_types.ml"
  | `Found
# 50 "cohttp/http_types.ml"
  | `See_other
# 51 "cohttp/http_types.ml"
  | `Not_modified
# 52 "cohttp/http_types.ml"
  | `Use_proxy
# 53 "cohttp/http_types.ml"
  | `Temporary_redirect
# 54 "cohttp/http_types.ml"
  ]
# 55 "cohttp/http_types.ml"
type client_error_status =
# 56 "cohttp/http_types.ml"
  [ `Bad_request
# 57 "cohttp/http_types.ml"
  | `Unauthorized
# 58 "cohttp/http_types.ml"
  | `Payment_required
# 59 "cohttp/http_types.ml"
  | `Forbidden
# 60 "cohttp/http_types.ml"
  | `Not_found
# 61 "cohttp/http_types.ml"
  | `Method_not_allowed
# 62 "cohttp/http_types.ml"
  | `Not_acceptable
# 63 "cohttp/http_types.ml"
  | `Proxy_authentication_required
# 64 "cohttp/http_types.ml"
  | `Request_time_out
# 65 "cohttp/http_types.ml"
  | `Conflict
# 66 "cohttp/http_types.ml"
  | `Gone
# 67 "cohttp/http_types.ml"
  | `Length_required
# 68 "cohttp/http_types.ml"
  | `Precondition_failed
# 69 "cohttp/http_types.ml"
  | `Request_entity_too_large
# 70 "cohttp/http_types.ml"
  | `Request_URI_too_large
# 71 "cohttp/http_types.ml"
  | `Unsupported_media_type
# 72 "cohttp/http_types.ml"
  | `Requested_range_not_satisfiable
# 73 "cohttp/http_types.ml"
  | `Expectation_failed
# 74 "cohttp/http_types.ml"
  ]
# 75 "cohttp/http_types.ml"
type server_error_status =
# 76 "cohttp/http_types.ml"
  [ `Internal_server_error
# 77 "cohttp/http_types.ml"
  | `Not_implemented
# 78 "cohttp/http_types.ml"
  | `Bad_gateway
# 79 "cohttp/http_types.ml"
  | `Service_unavailable
# 80 "cohttp/http_types.ml"
  | `Gateway_time_out
# 81 "cohttp/http_types.ml"
  | `HTTP_version_not_supported
# 82 "cohttp/http_types.ml"
  ]
# 83 "cohttp/http_types.ml"
type error_status =
# 84 "cohttp/http_types.ml"
  [ client_error_status
# 85 "cohttp/http_types.ml"
  | server_error_status
# 86 "cohttp/http_types.ml"
  ]
# 87 "cohttp/http_types.ml"
type status =
# 88 "cohttp/http_types.ml"
  [ informational_status
# 89 "cohttp/http_types.ml"
  | success_status
# 90 "cohttp/http_types.ml"
  | redirection_status
# 91 "cohttp/http_types.ml"
  | client_error_status
# 92 "cohttp/http_types.ml"
  | server_error_status
# 93 "cohttp/http_types.ml"
  ]
# 94 "cohttp/http_types.ml"

# 95 "cohttp/http_types.ml"
type status_code = [ `Code of int | status ]
# 96 "cohttp/http_types.ml"

# 97 "cohttp/http_types.ml"
exception Invalid_header of string
# 98 "cohttp/http_types.ml"
exception Invalid_header_name of string
# 99 "cohttp/http_types.ml"
exception Invalid_header_value of string
# 100 "cohttp/http_types.ml"
exception Invalid_HTTP_version of string
# 101 "cohttp/http_types.ml"
exception Invalid_HTTP_method of string
# 102 "cohttp/http_types.ml"
exception Invalid_code of int
# 103 "cohttp/http_types.ml"
exception Malformed_URL of string
# 104 "cohttp/http_types.ml"
exception Malformed_query of string
# 105 "cohttp/http_types.ml"
exception Malformed_query_part of string * string
# 106 "cohttp/http_types.ml"
exception Malformed_request_URI of string
# 107 "cohttp/http_types.ml"
exception Malformed_request of string
# 108 "cohttp/http_types.ml"
exception Malformed_response of string
# 109 "cohttp/http_types.ml"
exception Param_not_found of string
# 110 "cohttp/http_types.ml"
exception Invalid_status_line of string
# 111 "cohttp/http_types.ml"
exception Header_not_found of string
# 112 "cohttp/http_types.ml"
exception Unauthorized of string
# 113 "cohttp/http_types.ml"
end
module Http_constants : sig
# 1 "cohttp/http_constants.mli"

# 2 "cohttp/http_constants.mli"
(*
# 3 "cohttp/http_constants.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_constants.mli"

# 5 "cohttp/http_constants.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_constants.mli"

# 7 "cohttp/http_constants.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_constants.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_constants.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_constants.mli"

# 11 "cohttp/http_constants.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_constants.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_constants.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_constants.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_constants.mli"

# 16 "cohttp/http_constants.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_constants.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_constants.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_constants.mli"
  USA
# 20 "cohttp/http_constants.mli"
*)
# 21 "cohttp/http_constants.mli"

# 22 "cohttp/http_constants.mli"
(** Constants *)
# 23 "cohttp/http_constants.mli"

# 24 "cohttp/http_constants.mli"
val default_version: Http_types.version
# 25 "cohttp/http_constants.mli"

# 26 "cohttp/http_constants.mli"
val server_string: string
# 27 "cohttp/http_constants.mli"

# 28 "cohttp/http_constants.mli"
val crlf: string
# 29 "cohttp/http_constants.mli"
end = struct
# 1 "cohttp/http_constants.ml"

# 2 "cohttp/http_constants.ml"
(*
# 3 "cohttp/http_constants.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_constants.ml"

# 5 "cohttp/http_constants.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_constants.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 7 "cohttp/http_constants.ml"

# 8 "cohttp/http_constants.ml"
  This program is free software; you can redistribute it and/or modify
# 9 "cohttp/http_constants.ml"
  it under the terms of the GNU Library General Public License as
# 10 "cohttp/http_constants.ml"
  published by the Free Software Foundation, version 2.
# 11 "cohttp/http_constants.ml"

# 12 "cohttp/http_constants.ml"
  This program is distributed in the hope that it will be useful,
# 13 "cohttp/http_constants.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 14 "cohttp/http_constants.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 15 "cohttp/http_constants.ml"
  GNU Library General Public License for more details.
# 16 "cohttp/http_constants.ml"

# 17 "cohttp/http_constants.ml"
  You should have received a copy of the GNU Library General Public
# 18 "cohttp/http_constants.ml"
  License along with this program; if not, write to the Free Software
# 19 "cohttp/http_constants.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 20 "cohttp/http_constants.ml"
  USA
# 21 "cohttp/http_constants.ml"
*)
# 22 "cohttp/http_constants.ml"

# 23 "cohttp/http_constants.ml"
let default_version = `HTTP_1_1
# 24 "cohttp/http_constants.ml"
let server_string = "CoHTTP Daemon"
# 25 "cohttp/http_constants.ml"
let crlf = "\r\n"
# 26 "cohttp/http_constants.ml"
end
module Http_misc : sig
# 1 "cohttp/http_misc.mli"

# 2 "cohttp/http_misc.mli"
(*
# 3 "cohttp/http_misc.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_misc.mli"

# 5 "cohttp/http_misc.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_misc.mli"

# 7 "cohttp/http_misc.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_misc.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_misc.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_misc.mli"

# 11 "cohttp/http_misc.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_misc.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_misc.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_misc.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_misc.mli"

# 16 "cohttp/http_misc.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_misc.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_misc.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_misc.mli"
  USA
# 20 "cohttp/http_misc.mli"
*)
# 21 "cohttp/http_misc.mli"

# 22 "cohttp/http_misc.mli"
(** Helpers and other not better classified functions which should not be
# 23 "cohttp/http_misc.mli"
exposed in the final API *)
# 24 "cohttp/http_misc.mli"

# 25 "cohttp/http_misc.mli"
  (** @return the current date compliant to RFC 1123, which updates RFC 822
# 26 "cohttp/http_misc.mli"
  zone info are retrieved from UTC *)
# 27 "cohttp/http_misc.mli"
val date_822: unit -> string
# 28 "cohttp/http_misc.mli"

# 29 "cohttp/http_misc.mli"
(** Convert a number of seconds to a date compliant with RFC 822 *)
# 30 "cohttp/http_misc.mli"
val rfc822_of_float : float -> string
# 31 "cohttp/http_misc.mli"

# 32 "cohttp/http_misc.mli"
  (** strip trailing '/', if any, from a string and @return the new string *)
# 33 "cohttp/http_misc.mli"
val strip_trailing_slash: string -> string
# 34 "cohttp/http_misc.mli"

# 35 "cohttp/http_misc.mli"
  (** strip heading '/', if any, from a string and @return the new string *)
# 36 "cohttp/http_misc.mli"
val strip_heading_slash: string -> string
# 37 "cohttp/http_misc.mli"

# 38 "cohttp/http_misc.mli"
  (** explode a string in a char list *)
# 39 "cohttp/http_misc.mli"
val string_explode: string -> char list
# 40 "cohttp/http_misc.mli"

# 41 "cohttp/http_misc.mli"
  (** implode a char list in a string *)
# 42 "cohttp/http_misc.mli"
val string_implode: char list -> string
# 43 "cohttp/http_misc.mli"

# 44 "cohttp/http_misc.mli"
  (** given an HTTP response code return the corresponding reason phrase *)
# 45 "cohttp/http_misc.mli"
val reason_phrase_of_code: int -> string
# 46 "cohttp/http_misc.mli"

# 47 "cohttp/http_misc.mli"
  (** build a Channel.sockaddr inet address from a string representation of an IP
# 48 "cohttp/http_misc.mli"
  address and a port number *)
# 49 "cohttp/http_misc.mli"
val build_sockaddr: string * int -> Mlnet.Types.sockaddr Lwt.t
# 50 "cohttp/http_misc.mli"

# 51 "cohttp/http_misc.mli"
  (** explode an _inet_ Channel.sockaddr address in a string representation of an
# 52 "cohttp/http_misc.mli"
  IP address and a port number *)
# 53 "cohttp/http_misc.mli"
val explode_sockaddr: Mlnet.Types.sockaddr -> string * int
# 54 "cohttp/http_misc.mli"

# 55 "cohttp/http_misc.mli"
  (** like List.assoc but return all bindings of a given key instead of the
# 56 "cohttp/http_misc.mli"
  leftmost one only *)
# 57 "cohttp/http_misc.mli"
val list_assoc_all: 'a -> ('a * 'b) list -> 'b list
# 58 "cohttp/http_misc.mli"

# 59 "cohttp/http_misc.mli"
val warn: string -> unit (** print a warning msg to stderr. Adds trailing \n *)
# 60 "cohttp/http_misc.mli"
val error: string -> unit (** print an error msg to stderr. Adds trailing \n *)
# 61 "cohttp/http_misc.mli"

# 62 "cohttp/http_misc.mli"
end = struct
# 1 "cohttp/http_misc.ml"
(*
# 2 "cohttp/http_misc.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_misc.ml"

# 4 "cohttp/http_misc.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_misc.ml"
	              2006-2009 Citrix Systems Inc.
# 6 "cohttp/http_misc.ml"
	              2010 Thomas Gazagnaire <thomas@gazagnaire.com>
# 7 "cohttp/http_misc.ml"

# 8 "cohttp/http_misc.ml"
  This program is free software; you can redistribute it and/or modify
# 9 "cohttp/http_misc.ml"
  it under the terms of the GNU Library General Public License as
# 10 "cohttp/http_misc.ml"
  published by the Free Software Foundation, version 2.
# 11 "cohttp/http_misc.ml"

# 12 "cohttp/http_misc.ml"
  This program is distributed in the hope that it will be useful,
# 13 "cohttp/http_misc.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 14 "cohttp/http_misc.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 15 "cohttp/http_misc.ml"
  GNU Library General Public License for more details.
# 16 "cohttp/http_misc.ml"

# 17 "cohttp/http_misc.ml"
  You should have received a copy of the GNU Library General Public
# 18 "cohttp/http_misc.ml"
  License along with this program; if not, write to the Free Software
# 19 "cohttp/http_misc.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 20 "cohttp/http_misc.ml"
  USA
# 21 "cohttp/http_misc.ml"
*)
# 22 "cohttp/http_misc.ml"

# 23 "cohttp/http_misc.ml"
open Printf
# 24 "cohttp/http_misc.ml"
open Lwt
# 25 "cohttp/http_misc.ml"

# 26 "cohttp/http_misc.ml"
open Http_types
# 27 "cohttp/http_misc.ml"
open Mlnet.Types
# 28 "cohttp/http_misc.ml"

# 29 "cohttp/http_misc.ml"
let months = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun"; 
# 30 "cohttp/http_misc.ml"
   							"Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |]
# 31 "cohttp/http_misc.ml"
let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |]
# 32 "cohttp/http_misc.ml"

# 33 "cohttp/http_misc.ml"
let rfc822_of_float x =
# 34 "cohttp/http_misc.ml"
  let time = OS.Clock.gmtime x in
# 35 "cohttp/http_misc.ml"
  Printf.sprintf "%s, %d %s %d %02d:%02d:%02d GMT"
# 36 "cohttp/http_misc.ml"
    days.(time.OS.Clock.tm_wday) time.OS.Clock.tm_mday
# 37 "cohttp/http_misc.ml"
    months.(time.OS.Clock.tm_mon) (time.OS.Clock.tm_year+1900)
# 38 "cohttp/http_misc.ml"
    time.OS.Clock.tm_hour time.OS.Clock.tm_min time.OS.Clock.tm_sec
# 39 "cohttp/http_misc.ml"

# 40 "cohttp/http_misc.ml"
let date_822 () =
# 41 "cohttp/http_misc.ml"
  rfc822_of_float (OS.Clock.time ())
# 42 "cohttp/http_misc.ml"

# 43 "cohttp/http_misc.ml"
let strip_trailing_slash s =
# 44 "cohttp/http_misc.ml"
  match String.length s with
# 45 "cohttp/http_misc.ml"
  |0 -> s
# 46 "cohttp/http_misc.ml"
  |n -> if s.[n-1] = '/' then String.sub s 0 (n-1) else s
# 47 "cohttp/http_misc.ml"

# 48 "cohttp/http_misc.ml"
let strip_heading_slash s =
# 49 "cohttp/http_misc.ml"
  match String.length s with
# 50 "cohttp/http_misc.ml"
  |0 -> s
# 51 "cohttp/http_misc.ml"
  |n -> if s.[0] = '/' then String.sub s 1 (n-1) else s
# 52 "cohttp/http_misc.ml"

# 53 "cohttp/http_misc.ml"
let string_explode s =
# 54 "cohttp/http_misc.ml"
  let rec string_explode' acc = function
# 55 "cohttp/http_misc.ml"
    | "" -> acc
# 56 "cohttp/http_misc.ml"
    | s -> string_explode' (s.[0] :: acc) (String.sub s 1 (String.length s - 1))
# 57 "cohttp/http_misc.ml"
  in
# 58 "cohttp/http_misc.ml"
  List.rev (string_explode' [] s)
# 59 "cohttp/http_misc.ml"

# 60 "cohttp/http_misc.ml"
let string_implode = List.fold_left (fun s c -> s ^ (String.make 1 c)) ""
# 61 "cohttp/http_misc.ml"

# 62 "cohttp/http_misc.ml"
let reason_phrase_of_code = function
# 63 "cohttp/http_misc.ml"
  | 100 -> "Continue"
# 64 "cohttp/http_misc.ml"
  | 101 -> "Switching protocols"
# 65 "cohttp/http_misc.ml"
  | 200 -> "OK"
# 66 "cohttp/http_misc.ml"
  | 201 -> "Created"
# 67 "cohttp/http_misc.ml"
  | 202 -> "Accepted"
# 68 "cohttp/http_misc.ml"
  | 203 -> "Non authoritative information"
# 69 "cohttp/http_misc.ml"
  | 204 -> "No content"
# 70 "cohttp/http_misc.ml"
  | 205 -> "Reset content"
# 71 "cohttp/http_misc.ml"
  | 206 -> "Partial content"
# 72 "cohttp/http_misc.ml"
  | 300 -> "Multiple choices"
# 73 "cohttp/http_misc.ml"
  | 301 -> "Moved permanently"
# 74 "cohttp/http_misc.ml"
  | 302 -> "Found"
# 75 "cohttp/http_misc.ml"
  | 303 -> "See other"
# 76 "cohttp/http_misc.ml"
  | 304 -> "Not modified"
# 77 "cohttp/http_misc.ml"
  | 305 -> "Use proxy"
# 78 "cohttp/http_misc.ml"
  | 307 -> "Temporary redirect"
# 79 "cohttp/http_misc.ml"
  | 400 -> "Bad request"
# 80 "cohttp/http_misc.ml"
  | 401 -> "Unauthorized"
# 81 "cohttp/http_misc.ml"
  | 402 -> "Payment required"
# 82 "cohttp/http_misc.ml"
  | 403 -> "Forbidden"
# 83 "cohttp/http_misc.ml"
  | 404 -> "Not found"
# 84 "cohttp/http_misc.ml"
  | 405 -> "Method not allowed"
# 85 "cohttp/http_misc.ml"
  | 406 -> "Not acceptable"
# 86 "cohttp/http_misc.ml"
  | 407 -> "Proxy authentication required"
# 87 "cohttp/http_misc.ml"
  | 408 -> "Request time out"
# 88 "cohttp/http_misc.ml"
  | 409 -> "Conflict"
# 89 "cohttp/http_misc.ml"
  | 410 -> "Gone"
# 90 "cohttp/http_misc.ml"
  | 411 -> "Length required"
# 91 "cohttp/http_misc.ml"
  | 412 -> "Precondition failed"
# 92 "cohttp/http_misc.ml"
  | 413 -> "Request entity too large"
# 93 "cohttp/http_misc.ml"
  | 414 -> "Request URI too large"
# 94 "cohttp/http_misc.ml"
  | 415 -> "Unsupported media type"
# 95 "cohttp/http_misc.ml"
  | 416 -> "Requested range not satisfiable"
# 96 "cohttp/http_misc.ml"
  | 417 -> "Expectation failed"
# 97 "cohttp/http_misc.ml"
  | 500 -> "Internal server error"
# 98 "cohttp/http_misc.ml"
  | 501 -> "Not implemented"
# 99 "cohttp/http_misc.ml"
  | 502 -> "Bad gateway"
# 100 "cohttp/http_misc.ml"
  | 503 -> "Service unavailable"
# 101 "cohttp/http_misc.ml"
  | 504 -> "Gateway time out"
# 102 "cohttp/http_misc.ml"
  | 505 -> "HTTP version not supported"
# 103 "cohttp/http_misc.ml"
  | invalid_code -> raise (Invalid_code invalid_code)
# 104 "cohttp/http_misc.ml"

# 105 "cohttp/http_misc.ml"
let build_sockaddr (addr, port) =
# 106 "cohttp/http_misc.ml"
  try_lwt
# 107 "cohttp/http_misc.ml"
    (* should this be lwt hent = Lwt_lib.gethostbyname addr ? *)
# 108 "cohttp/http_misc.ml"
    (* XXX: no DNS client at the moment *)
# 109 "cohttp/http_misc.ml"
    (* let hent = Unix.gethostbyname addr in *)
# 110 "cohttp/http_misc.ml"
    (* return (Unix.ADDR_INET (hent.Unix.h_addr_list.(0), port)) *)
# 111 "cohttp/http_misc.ml"
    let ip = match Mlnet.Types.ipv4_addr_of_string addr with
# 112 "cohttp/http_misc.ml"
      | Some x -> x
# 113 "cohttp/http_misc.ml"
      | None -> failwith "ip" in
# 114 "cohttp/http_misc.ml"
    return (TCP (ip, port))
# 115 "cohttp/http_misc.ml"
  with _ -> failwith ("ocaml-cohttp, cant resolve hostname: " ^ addr)
# 116 "cohttp/http_misc.ml"
     
# 117 "cohttp/http_misc.ml"
let explode_sockaddr = function
# 118 "cohttp/http_misc.ml"
  | TCP (ip, port) -> (Mlnet.Types.ipv4_addr_to_string ip, port)
# 119 "cohttp/http_misc.ml"
  | _ -> assert false (* can explode only inet address *)
# 120 "cohttp/http_misc.ml"

# 121 "cohttp/http_misc.ml"
let list_assoc_all key pairs =
# 122 "cohttp/http_misc.ml"
  snd (List.split (List.filter (fun (k, v) -> k = key) pairs))
# 123 "cohttp/http_misc.ml"

# 124 "cohttp/http_misc.ml"
let warn msg  = prerr_endline (sprintf "ocaml-cohttp WARNING: %s" msg)
# 125 "cohttp/http_misc.ml"
let error msg = prerr_endline (sprintf "ocaml-cohttp ERROR:   %s" msg)
# 126 "cohttp/http_misc.ml"
end
module Base64 : sig
# 1 "cohttp/base64.mli"
(*
# 2 "cohttp/base64.mli"
 * Copyright (C) 2006-2009 Citrix Systems Inc.
# 3 "cohttp/base64.mli"
 *
# 4 "cohttp/base64.mli"
 * This program is free software; you can redistribute it and/or modify
# 5 "cohttp/base64.mli"
 * it under the terms of the GNU Lesser General Public License as published
# 6 "cohttp/base64.mli"
 * by the Free Software Foundation; version 2.1 only. with the special
# 7 "cohttp/base64.mli"
 * exception on linking described in file LICENSE.
# 8 "cohttp/base64.mli"
 *
# 9 "cohttp/base64.mli"
 * This program is distributed in the hope that it will be useful,
# 10 "cohttp/base64.mli"
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
# 11 "cohttp/base64.mli"
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 12 "cohttp/base64.mli"
 * GNU Lesser General Public License for more details.
# 13 "cohttp/base64.mli"
 *)
# 14 "cohttp/base64.mli"

# 15 "cohttp/base64.mli"
(** decode a string encoded in base64. Will leave trailing NULLs on the string
# 16 "cohttp/base64.mli"
    padding it out to a multiple of 3 characters *)
# 17 "cohttp/base64.mli"
val decode: string -> string
# 18 "cohttp/base64.mli"

# 19 "cohttp/base64.mli"
(** encode a string into base64 *)
# 20 "cohttp/base64.mli"
val encode: string -> string
# 21 "cohttp/base64.mli"
end = struct
# 1 "cohttp/base64.ml"
(*
# 2 "cohttp/base64.ml"
 * Copyright (C) 2006-2009 Citrix Systems Inc.
# 3 "cohttp/base64.ml"
 *               2010 Thomas Gazagnaire <thomas@gazagnaire.com>
# 4 "cohttp/base64.ml"
 *
# 5 "cohttp/base64.ml"
 * This program is free software; you can redistribute it and/or modify
# 6 "cohttp/base64.ml"
 * it under the terms of the GNU Lesser General Public License as published
# 7 "cohttp/base64.ml"
 * by the Free Software Foundation; version 2.1 only. with the special
# 8 "cohttp/base64.ml"
 * exception on linking described in file LICENSE.
# 9 "cohttp/base64.ml"
 *
# 10 "cohttp/base64.ml"
 * This program is distributed in the hope that it will be useful,
# 11 "cohttp/base64.ml"
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
# 12 "cohttp/base64.ml"
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 13 "cohttp/base64.ml"
 * GNU Lesser General Public License for more details.
# 14 "cohttp/base64.ml"
 *)
# 15 "cohttp/base64.ml"

# 16 "cohttp/base64.ml"
let code = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
# 17 "cohttp/base64.ml"
let padding = '='
# 18 "cohttp/base64.ml"

# 19 "cohttp/base64.ml"
let of_char x = if x = padding then 0 else String.index code x
# 20 "cohttp/base64.ml"

# 21 "cohttp/base64.ml"
let to_char x = code.[x]
# 22 "cohttp/base64.ml"

# 23 "cohttp/base64.ml"
let decode x = 
# 24 "cohttp/base64.ml"
  let words = String.length x / 4 in
# 25 "cohttp/base64.ml"
  let padding = 
# 26 "cohttp/base64.ml"
    if String.length x = 0 then 0 else (
# 27 "cohttp/base64.ml"
    if x.[String.length x - 2] = padding
# 28 "cohttp/base64.ml"
    then 2 else (if x.[String.length x - 1] = padding then 1 else 0)) in
# 29 "cohttp/base64.ml"
  let output = String.make (words * 3 - padding) '\000' in
# 30 "cohttp/base64.ml"
  for i = 0 to words - 1 do
# 31 "cohttp/base64.ml"
    let a = of_char x.[4 * i + 0]
# 32 "cohttp/base64.ml"
    and b = of_char x.[4 * i + 1]
# 33 "cohttp/base64.ml"
    and c = of_char x.[4 * i + 2]
# 34 "cohttp/base64.ml"
    and d = of_char x.[4 * i + 3] in
# 35 "cohttp/base64.ml"
    let n = (a lsl 18) lor (b lsl 12) lor (c lsl 6) lor d in
# 36 "cohttp/base64.ml"
    let x = (n lsr 16) land 255
# 37 "cohttp/base64.ml"
    and y = (n lsr 8) land 255
# 38 "cohttp/base64.ml"
    and z = n land 255 in
# 39 "cohttp/base64.ml"
    output.[3 * i + 0] <- char_of_int x;
# 40 "cohttp/base64.ml"
    if i <> words - 1 || padding < 2 then output.[3 * i + 1] <- char_of_int y;
# 41 "cohttp/base64.ml"
    if i <> words - 1 || padding < 1 then output.[3 * i + 2] <- char_of_int z;
# 42 "cohttp/base64.ml"
  done;
# 43 "cohttp/base64.ml"
  output
# 44 "cohttp/base64.ml"

# 45 "cohttp/base64.ml"
let encode x = 
# 46 "cohttp/base64.ml"
  let length = String.length x in
# 47 "cohttp/base64.ml"
  let words = (length + 2) / 3 in (* rounded up *)
# 48 "cohttp/base64.ml"
  let padding = if length mod 3 = 0 then 0 else 3 - (length mod 3) in
# 49 "cohttp/base64.ml"
  let output = String.make (words * 4) '\000' in
# 50 "cohttp/base64.ml"
  let get i = if i >= length then 0 else int_of_char x.[i] in
# 51 "cohttp/base64.ml"
  for i = 0 to words - 1 do
# 52 "cohttp/base64.ml"
    let x = get (3 * i + 0)
# 53 "cohttp/base64.ml"
    and y = get (3 * i + 1)
# 54 "cohttp/base64.ml"
    and z = get (3 * i + 2) in
# 55 "cohttp/base64.ml"
    let n = (x lsl 16) lor (y lsl 8) lor z in 
# 56 "cohttp/base64.ml"
    let a = (n lsr 18) land 63
# 57 "cohttp/base64.ml"
    and b = (n lsr 12) land 63
# 58 "cohttp/base64.ml"
    and c = (n lsr 6) land 63
# 59 "cohttp/base64.ml"
    and d = n land 63 in
# 60 "cohttp/base64.ml"
    output.[4 * i + 0] <- to_char a;
# 61 "cohttp/base64.ml"
    output.[4 * i + 1] <- to_char b;
# 62 "cohttp/base64.ml"
    output.[4 * i + 2] <- to_char c;
# 63 "cohttp/base64.ml"
    output.[4 * i + 3] <- to_char d;
# 64 "cohttp/base64.ml"
  done;
# 65 "cohttp/base64.ml"
  for i = 1 to padding do
# 66 "cohttp/base64.ml"
    output.[String.length output - i] <- '=';
# 67 "cohttp/base64.ml"
  done;
# 68 "cohttp/base64.ml"
  output
# 69 "cohttp/base64.ml"

# 70 "cohttp/base64.ml"
let test x = 
# 71 "cohttp/base64.ml"
  let x' = encode x in
# 72 "cohttp/base64.ml"
  let x'' = decode x' in
# 73 "cohttp/base64.ml"
  if x <> x'' 
# 74 "cohttp/base64.ml"
  then failwith (Printf.sprintf "Original: '%s'; encoded = '%s'; decoded = '%s'" x x' x'')
# 75 "cohttp/base64.ml"

# 76 "cohttp/base64.ml"
let tests = [ "hello"; 
# 77 "cohttp/base64.ml"
	      "this is a basic test"; "1"; "22"; "333"; "4444"; "5555";
# 78 "cohttp/base64.ml"
	      "\000"; "\000\000"; "\000\000\000"; "\000\000\000\000" ]
# 79 "cohttp/base64.ml"

# 80 "cohttp/base64.ml"
(*
# 81 "cohttp/base64.ml"
let _ = List.iter test tests
# 82 "cohttp/base64.ml"
*)
# 83 "cohttp/base64.ml"
end
module Http_url : sig
# 1 "cohttp/http_url.mli"
(*
# 2 "cohttp/http_url.mli"
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
# 3 "cohttp/http_url.mli"
 *
# 4 "cohttp/http_url.mli"
 * Permission to use, copy, modify, and distribute this software for any
# 5 "cohttp/http_url.mli"
 * purpose with or without fee is hereby granted, provided that the above
# 6 "cohttp/http_url.mli"
 * copyright notice and this permission notice appear in all copies.
# 7 "cohttp/http_url.mli"
 *
# 8 "cohttp/http_url.mli"
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# 9 "cohttp/http_url.mli"
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# 10 "cohttp/http_url.mli"
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# 11 "cohttp/http_url.mli"
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# 12 "cohttp/http_url.mli"
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# 13 "cohttp/http_url.mli"
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# 14 "cohttp/http_url.mli"
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 15 "cohttp/http_url.mli"
 *)
# 16 "cohttp/http_url.mli"

# 17 "cohttp/http_url.mli"
(** URL type *)
# 18 "cohttp/http_url.mli"
type t
# 19 "cohttp/http_url.mli"

# 20 "cohttp/http_url.mli"
(** Get the path out of the URL *)
# 21 "cohttp/http_url.mli"
val path : t -> string option
# 22 "cohttp/http_url.mli"

# 23 "cohttp/http_url.mli"
(** Get the query out of an URL *)
# 24 "cohttp/http_url.mli"
val query : t -> string option
# 25 "cohttp/http_url.mli"

# 26 "cohttp/http_url.mli"
(** Build an encoded string from an URL *)
# 27 "cohttp/http_url.mli"
val to_string : t -> string
# 28 "cohttp/http_url.mli"

# 29 "cohttp/http_url.mli"
(** Build an URL from an encoded string *)
# 30 "cohttp/http_url.mli"
val of_string : string -> t
# 31 "cohttp/http_url.mli"

# 32 "cohttp/http_url.mli"
(** URL encode the string *)
# 33 "cohttp/http_url.mli"
val encode : string -> string
# 34 "cohttp/http_url.mli"

# 35 "cohttp/http_url.mli"
(** URL decode the string *)
# 36 "cohttp/http_url.mli"
val decode : string -> string
# 37 "cohttp/http_url.mli"
end = struct
# 1 "cohttp/http_url.ml"
(*
# 2 "cohttp/http_url.ml"
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
# 3 "cohttp/http_url.ml"
 *
# 4 "cohttp/http_url.ml"
 * Permission to use, copy, modify, and distribute this software for any
# 5 "cohttp/http_url.ml"
 * purpose with or without fee is hereby granted, provided that the above
# 6 "cohttp/http_url.ml"
 * copyright notice and this permission notice appear in all copies.
# 7 "cohttp/http_url.ml"
 *
# 8 "cohttp/http_url.ml"
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# 9 "cohttp/http_url.ml"
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# 10 "cohttp/http_url.ml"
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# 11 "cohttp/http_url.ml"
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# 12 "cohttp/http_url.ml"
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# 13 "cohttp/http_url.ml"
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# 14 "cohttp/http_url.ml"
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 15 "cohttp/http_url.ml"
 *)
# 16 "cohttp/http_url.ml"

# 17 "cohttp/http_url.ml"
(* From http://www.blooberry.com/indexdot/html/topics/urlencoding.htm#how *)
# 18 "cohttp/http_url.ml"
let url_encoding = Str.regexp (
# 19 "cohttp/http_url.ml"
  "[\x00-\x1F\x7F" ^ (* ASCII control chars *)
# 20 "cohttp/http_url.ml"
  "\x80-\xFF" ^ (* non-ASCII chars *)
# 21 "cohttp/http_url.ml"
  "\x24\x26\x2B\x2C\x2F\x3A\x3B\x3D\x3F\x40" ^ (* Reserved chars *)
# 22 "cohttp/http_url.ml"
  "\x20\x22\x3C\x3E\x23\x25\x7B\x7D\x7C\x5C\x5E\x7E\x5B\\x5D\x60]" (* unsafe chars *)
# 23 "cohttp/http_url.ml"
)
# 24 "cohttp/http_url.ml"

# 25 "cohttp/http_url.ml"
let encoding str =
# 26 "cohttp/http_url.ml"
  let c = Str.matched_string str in
# 27 "cohttp/http_url.ml"
  Printf.sprintf "%%%X" (Char.code c.[0])
# 28 "cohttp/http_url.ml"
  
# 29 "cohttp/http_url.ml"
let encode str =
# 30 "cohttp/http_url.ml"
  Str.global_substitute url_encoding encoding str
# 31 "cohttp/http_url.ml"

# 32 "cohttp/http_url.ml"
let url_decoding = Str.regexp "%[0-9][0-9]"
# 33 "cohttp/http_url.ml"

# 34 "cohttp/http_url.ml"
let decoding str =
# 35 "cohttp/http_url.ml"
  let str = Str.matched_string str in
# 36 "cohttp/http_url.ml"
  let s = String.create 4 in
# 37 "cohttp/http_url.ml"
  s.[0] <- '0';
# 38 "cohttp/http_url.ml"
  s.[1] <- 'x';
# 39 "cohttp/http_url.ml"
  s.[2] <- str.[1];
# 40 "cohttp/http_url.ml"
  s.[3] <- str.[2];
# 41 "cohttp/http_url.ml"
  String.make 1 (Char.chr (int_of_string s))
# 42 "cohttp/http_url.ml"
 
# 43 "cohttp/http_url.ml"
let decode str =
# 44 "cohttp/http_url.ml"
  Str.global_substitute url_decoding decoding str
# 45 "cohttp/http_url.ml"

# 46 "cohttp/http_url.ml"
(*
# 47 "cohttp/http_url.ml"
let _ =
# 48 "cohttp/http_url.ml"
  let i = "foo$bar$"in
# 49 "cohttp/http_url.ml"
  let e = encode i in
# 50 "cohttp/http_url.ml"
  let d = decode e in
# 51 "cohttp/http_url.ml"
  Printf.printf "init: %s\nencode : %s\ndecode: %s\n" i e d
# 52 "cohttp/http_url.ml"
*)
# 53 "cohttp/http_url.ml"

# 54 "cohttp/http_url.ml"
type t = {
# 55 "cohttp/http_url.ml"
  scheme : string option;
# 56 "cohttp/http_url.ml"
  userinfo: string option;
# 57 "cohttp/http_url.ml"
  host : string;
# 58 "cohttp/http_url.ml"
  port: int option;
# 59 "cohttp/http_url.ml"
  path : string option;
# 60 "cohttp/http_url.ml"
  query : string option;
# 61 "cohttp/http_url.ml"
  fragment : string option;
# 62 "cohttp/http_url.ml"
}
# 63 "cohttp/http_url.ml"

# 64 "cohttp/http_url.ml"
let path t = t.path
# 65 "cohttp/http_url.ml"
let query t = t.query
# 66 "cohttp/http_url.ml"

# 67 "cohttp/http_url.ml"
(* From http://www.filbar.org/weblog/parsing_incomplete_or_malformed_urls_with_regular_expressions *)
# 68 "cohttp/http_url.ml"
let url_regexp = Str.regexp (
# 69 "cohttp/http_url.ml"
  "\\(\\([A-Za-z0-9_+.]+\\):\\)?\\(//\\)?" ^ (* scheme *)
# 70 "cohttp/http_url.ml"
  "\\(\\([!-~]+\\)@\\)?" ^                   (* userinfo *)
# 71 "cohttp/http_url.ml"
  "\\([^/?#:]*\\)" ^                         (* host *)
# 72 "cohttp/http_url.ml"
  "\\(:\\([0-9]*\\)\\)?" ^                   (* port *)
# 73 "cohttp/http_url.ml"
  "\\(/\\([^?#]*\\)\\)?" ^                   (* path *)
# 74 "cohttp/http_url.ml"
  "\\(\\?\\([^#]*\\)\\)?" ^                  (* query *)
# 75 "cohttp/http_url.ml"
  "\\(#\\(.*\\)\\)?"                         (* fragment *)
# 76 "cohttp/http_url.ml"
)
# 77 "cohttp/http_url.ml"

# 78 "cohttp/http_url.ml"
type url_fragments = Scheme | Userinfo | Host | Port | Path | Query | Fragment
# 79 "cohttp/http_url.ml"

# 80 "cohttp/http_url.ml"
let names = [
# 81 "cohttp/http_url.ml"
  Scheme,   2;
# 82 "cohttp/http_url.ml"
  Userinfo, 5;
# 83 "cohttp/http_url.ml"
  Host,     6;
# 84 "cohttp/http_url.ml"
  Port,     8;
# 85 "cohttp/http_url.ml"
  Path,     10;
# 86 "cohttp/http_url.ml"
  Query,    12;
# 87 "cohttp/http_url.ml"
  Fragment, 14;
# 88 "cohttp/http_url.ml"
]
# 89 "cohttp/http_url.ml"

# 90 "cohttp/http_url.ml"
let get n str =
# 91 "cohttp/http_url.ml"
  try Some (Str.matched_group (List.assoc n names) str)
# 92 "cohttp/http_url.ml"
  with Not_found -> None
# 93 "cohttp/http_url.ml"

# 94 "cohttp/http_url.ml"
(*
# 95 "cohttp/http_url.ml"
let _ =
# 96 "cohttp/http_url.ml"
  let url = "foo://john.doo@example.com:8042/over/there?name=ferret#nose" in
# 97 "cohttp/http_url.ml"
  let get n s =
# 98 "cohttp/http_url.ml"
    match get n url with
# 99 "cohttp/http_url.ml"
    | Some x -> Printf.printf "%s: %s\n%!" n x
# 100 "cohttp/http_url.ml"
    | None   -> Printf.printf "%s: <none>\n%!" n in
# 101 "cohttp/http_url.ml"
  if Str.string_match url_regexp url 0 then begin
# 102 "cohttp/http_url.ml"
    get "scheme" url;
# 103 "cohttp/http_url.ml"
    get "userinfo" url;
# 104 "cohttp/http_url.ml"
    get "host" url;
# 105 "cohttp/http_url.ml"
    get "port" url;
# 106 "cohttp/http_url.ml"
    get "path" url;
# 107 "cohttp/http_url.ml"
    get "query" url;
# 108 "cohttp/http_url.ml"
    get "fragment" url
# 109 "cohttp/http_url.ml"
  end else
# 110 "cohttp/http_url.ml"
    Printf.printf "URL don't match !!!\n"
# 111 "cohttp/http_url.ml"
*)
# 112 "cohttp/http_url.ml"

# 113 "cohttp/http_url.ml"
let of_string str =
# 114 "cohttp/http_url.ml"
  if Str.string_match url_regexp str 0 then
# 115 "cohttp/http_url.ml"
    let get n = get n str in
# 116 "cohttp/http_url.ml"
    {
# 117 "cohttp/http_url.ml"
      scheme = get Scheme;
# 118 "cohttp/http_url.ml"
      userinfo = get Userinfo;
# 119 "cohttp/http_url.ml"
      host = (match get Host with None -> failwith "of_string" | Some x -> x);
# 120 "cohttp/http_url.ml"
      port = (match get Port with Some p -> Some (int_of_string p) | None -> None);
# 121 "cohttp/http_url.ml"
      path = get Path;
# 122 "cohttp/http_url.ml"
      query = get Query;
# 123 "cohttp/http_url.ml"
      fragment = get Fragment;
# 124 "cohttp/http_url.ml"
    }
# 125 "cohttp/http_url.ml"
  else raise (Http_types.Malformed_URL str)
# 126 "cohttp/http_url.ml"
  
# 127 "cohttp/http_url.ml"
open Printf
# 128 "cohttp/http_url.ml"

# 129 "cohttp/http_url.ml"
let to_string url =
# 130 "cohttp/http_url.ml"
  let scheme = match url.scheme with
# 131 "cohttp/http_url.ml"
    | Some s -> sprintf "%s://" s
# 132 "cohttp/http_url.ml"
    | None   -> "" in
# 133 "cohttp/http_url.ml"
  let userinfo = match url.userinfo with
# 134 "cohttp/http_url.ml"
    | Some s -> sprintf "%s@" s
# 135 "cohttp/http_url.ml"
    | None   -> "" in
# 136 "cohttp/http_url.ml"
  let host = url.host in
# 137 "cohttp/http_url.ml"
  let port = match url.port with
# 138 "cohttp/http_url.ml"
    | Some i -> sprintf ":%d" i
# 139 "cohttp/http_url.ml"
    | None   -> "" in
# 140 "cohttp/http_url.ml"
  let path = match url.path with
# 141 "cohttp/http_url.ml"
    | Some s -> sprintf "/%s" s
# 142 "cohttp/http_url.ml"
    | None   -> "" in
# 143 "cohttp/http_url.ml"
  let query = match url.query with
# 144 "cohttp/http_url.ml"
    | Some s -> sprintf "?%s" s
# 145 "cohttp/http_url.ml"
    | None   -> "" in
# 146 "cohttp/http_url.ml"
  let fragment = match url.fragment with
# 147 "cohttp/http_url.ml"
    | Some s -> sprintf "#%s" s
# 148 "cohttp/http_url.ml"
    | None   -> "" in
# 149 "cohttp/http_url.ml"
  encode (sprintf "%s%s%s%s%s%s%s" scheme userinfo host port path query fragment)
# 150 "cohttp/http_url.ml"
  
# 151 "cohttp/http_url.ml"
end
module Http_common : sig
# 1 "cohttp/http_common.mli"

# 2 "cohttp/http_common.mli"
(*
# 3 "cohttp/http_common.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_common.mli"

# 5 "cohttp/http_common.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_common.mli"

# 7 "cohttp/http_common.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_common.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_common.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_common.mli"

# 11 "cohttp/http_common.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_common.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_common.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_common.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_common.mli"

# 16 "cohttp/http_common.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_common.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_common.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_common.mli"
  USA
# 20 "cohttp/http_common.mli"
*)
# 21 "cohttp/http_common.mli"

# 22 "cohttp/http_common.mli"
(** Common functionalities shared by other OCaml HTTP modules *)
# 23 "cohttp/http_common.mli"

# 24 "cohttp/http_common.mli"
open Http_types;;
# 25 "cohttp/http_common.mli"

# 26 "cohttp/http_common.mli"
  (** whether debugging messages are enabled or not, can be changed at runtime
# 27 "cohttp/http_common.mli"
  *)
# 28 "cohttp/http_common.mli"
val debug: bool ref
# 29 "cohttp/http_common.mli"

# 30 "cohttp/http_common.mli"
  (** print a string on stderr only if debugging is enabled *)
# 31 "cohttp/http_common.mli"
val debug_print: string -> unit
# 32 "cohttp/http_common.mli"

# 33 "cohttp/http_common.mli"
  (** pretty print an HTTP version *)
# 34 "cohttp/http_common.mli"
val string_of_version: version -> string
# 35 "cohttp/http_common.mli"

# 36 "cohttp/http_common.mli"
  (** parse an HTTP version from a string
# 37 "cohttp/http_common.mli"
  @raise Invalid_HTTP_version if given string doesn't represent a supported HTTP
# 38 "cohttp/http_common.mli"
  version *)
# 39 "cohttp/http_common.mli"
val version_of_string: string -> version
# 40 "cohttp/http_common.mli"

# 41 "cohttp/http_common.mli"
  (** pretty print an HTTP method *)
# 42 "cohttp/http_common.mli"
val string_of_method: meth -> string
# 43 "cohttp/http_common.mli"

# 44 "cohttp/http_common.mli"
  (** parse an HTTP method from a string
# 45 "cohttp/http_common.mli"
  @raise Invalid_HTTP_method if given string doesn't represent a supported
# 46 "cohttp/http_common.mli"
  method *)
# 47 "cohttp/http_common.mli"
val method_of_string: string -> meth
# 48 "cohttp/http_common.mli"

# 49 "cohttp/http_common.mli"
  (** converts an integer HTTP status to the corresponding status value
# 50 "cohttp/http_common.mli"
  @raise Invalid_code if given integer isn't a valid HTTP status code *)
# 51 "cohttp/http_common.mli"
val status_of_code: int -> status
# 52 "cohttp/http_common.mli"

# 53 "cohttp/http_common.mli"
  (** converts an HTTP status to the corresponding integer value *)
# 54 "cohttp/http_common.mli"
val code_of_status: [< status] -> int
# 55 "cohttp/http_common.mli"

# 56 "cohttp/http_common.mli"
  (** @return true on "informational" status codes, false elsewhere *)
# 57 "cohttp/http_common.mli"
val is_informational: int -> bool
# 58 "cohttp/http_common.mli"

# 59 "cohttp/http_common.mli"
  (** @return true on "success" status codes, false elsewhere *)
# 60 "cohttp/http_common.mli"
val is_success: int -> bool
# 61 "cohttp/http_common.mli"

# 62 "cohttp/http_common.mli"
  (** @return true on "redirection" status codes, false elsewhere *)
# 63 "cohttp/http_common.mli"
val is_redirection: int -> bool
# 64 "cohttp/http_common.mli"

# 65 "cohttp/http_common.mli"
  (** @return true on "client error" status codes, false elsewhere *)
# 66 "cohttp/http_common.mli"
val is_client_error: int -> bool
# 67 "cohttp/http_common.mli"

# 68 "cohttp/http_common.mli"
  (** @return true on "server error" status codes, false elsewhere *)
# 69 "cohttp/http_common.mli"
val is_server_error: int -> bool
# 70 "cohttp/http_common.mli"

# 71 "cohttp/http_common.mli"
  (** @return true on "client error" and "server error" status code, false
# 72 "cohttp/http_common.mli"
  elsewhere *)
# 73 "cohttp/http_common.mli"
val is_error: int -> bool
# 74 "cohttp/http_common.mli"

# 75 "cohttp/http_common.mli"
end = struct
# 1 "cohttp/http_common.ml"

# 2 "cohttp/http_common.ml"
(*
# 3 "cohttp/http_common.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_common.ml"

# 5 "cohttp/http_common.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_common.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 7 "cohttp/http_common.ml"

# 8 "cohttp/http_common.ml"
  This program is free software; you can redistribute it and/or modify
# 9 "cohttp/http_common.ml"
  it under the terms of the GNU Library General Public License as
# 10 "cohttp/http_common.ml"
  published by the Free Software Foundation, version 2.
# 11 "cohttp/http_common.ml"

# 12 "cohttp/http_common.ml"
  This program is distributed in the hope that it will be useful,
# 13 "cohttp/http_common.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 14 "cohttp/http_common.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 15 "cohttp/http_common.ml"
  GNU Library General Public License for more details.
# 16 "cohttp/http_common.ml"

# 17 "cohttp/http_common.ml"
  You should have received a copy of the GNU Library General Public
# 18 "cohttp/http_common.ml"
  License along with this program; if not, write to the Free Software
# 19 "cohttp/http_common.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 20 "cohttp/http_common.ml"
  USA
# 21 "cohttp/http_common.ml"
*)
# 22 "cohttp/http_common.ml"

# 23 "cohttp/http_common.ml"
open Http_types;;
# 24 "cohttp/http_common.ml"
open Printf;;
# 25 "cohttp/http_common.ml"

# 26 "cohttp/http_common.ml"
let debug = ref false
# 27 "cohttp/http_common.ml"
let debug_print s =
# 28 "cohttp/http_common.ml"
  if !debug then
# 29 "cohttp/http_common.ml"
    prerr_endline (sprintf "[OCaml HTTP] DEBUG: %s" s)
# 30 "cohttp/http_common.ml"

# 31 "cohttp/http_common.ml"
let string_of_version = function
# 32 "cohttp/http_common.ml"
  | `HTTP_1_0 -> "HTTP/1.0"
# 33 "cohttp/http_common.ml"
  | `HTTP_1_1 -> "HTTP/1.1"
# 34 "cohttp/http_common.ml"

# 35 "cohttp/http_common.ml"
let version_of_string = function
# 36 "cohttp/http_common.ml"
  | "HTTP/1.0" -> `HTTP_1_0
# 37 "cohttp/http_common.ml"
  | "HTTP/1.1" -> `HTTP_1_1
# 38 "cohttp/http_common.ml"
  | invalid_version -> raise (Invalid_HTTP_version invalid_version)
# 39 "cohttp/http_common.ml"

# 40 "cohttp/http_common.ml"
let string_of_method = function
# 41 "cohttp/http_common.ml"
  | `GET -> "GET"
# 42 "cohttp/http_common.ml"
  | `POST -> "POST"
# 43 "cohttp/http_common.ml"
  | `HEAD -> "HEAD"
# 44 "cohttp/http_common.ml"
  | `DELETE -> "DELETE"
# 45 "cohttp/http_common.ml"

# 46 "cohttp/http_common.ml"
let method_of_string = function
# 47 "cohttp/http_common.ml"
  | "GET" -> `GET
# 48 "cohttp/http_common.ml"
  | "POST" -> `POST
# 49 "cohttp/http_common.ml"
  | "HEAD" -> `HEAD
# 50 "cohttp/http_common.ml"
  | "DELETE" -> `DELETE
# 51 "cohttp/http_common.ml"
  | invalid_method -> raise (Invalid_HTTP_method invalid_method)
# 52 "cohttp/http_common.ml"

# 53 "cohttp/http_common.ml"
let status_of_code = function
# 54 "cohttp/http_common.ml"
  | 100 -> `Continue
# 55 "cohttp/http_common.ml"
  | 101 -> `Switching_protocols
# 56 "cohttp/http_common.ml"
  | 200 -> `OK
# 57 "cohttp/http_common.ml"
  | 201 -> `Created
# 58 "cohttp/http_common.ml"
  | 202 -> `Accepted
# 59 "cohttp/http_common.ml"
  | 203 -> `Non_authoritative_information
# 60 "cohttp/http_common.ml"
  | 204 -> `No_content
# 61 "cohttp/http_common.ml"
  | 205 -> `Reset_content
# 62 "cohttp/http_common.ml"
  | 206 -> `Partial_content
# 63 "cohttp/http_common.ml"
  | 300 -> `Multiple_choices
# 64 "cohttp/http_common.ml"
  | 301 -> `Moved_permanently
# 65 "cohttp/http_common.ml"
  | 302 -> `Found
# 66 "cohttp/http_common.ml"
  | 303 -> `See_other
# 67 "cohttp/http_common.ml"
  | 304 -> `Not_modified
# 68 "cohttp/http_common.ml"
  | 305 -> `Use_proxy
# 69 "cohttp/http_common.ml"
  | 307 -> `Temporary_redirect
# 70 "cohttp/http_common.ml"
  | 400 -> `Bad_request
# 71 "cohttp/http_common.ml"
  | 401 -> `Unauthorized
# 72 "cohttp/http_common.ml"
  | 402 -> `Payment_required
# 73 "cohttp/http_common.ml"
  | 403 -> `Forbidden
# 74 "cohttp/http_common.ml"
  | 404 -> `Not_found
# 75 "cohttp/http_common.ml"
  | 405 -> `Method_not_allowed
# 76 "cohttp/http_common.ml"
  | 406 -> `Not_acceptable
# 77 "cohttp/http_common.ml"
  | 407 -> `Proxy_authentication_required
# 78 "cohttp/http_common.ml"
  | 408 -> `Request_time_out
# 79 "cohttp/http_common.ml"
  | 409 -> `Conflict
# 80 "cohttp/http_common.ml"
  | 410 -> `Gone
# 81 "cohttp/http_common.ml"
  | 411 -> `Length_required
# 82 "cohttp/http_common.ml"
  | 412 -> `Precondition_failed
# 83 "cohttp/http_common.ml"
  | 413 -> `Request_entity_too_large
# 84 "cohttp/http_common.ml"
  | 414 -> `Request_URI_too_large
# 85 "cohttp/http_common.ml"
  | 415 -> `Unsupported_media_type
# 86 "cohttp/http_common.ml"
  | 416 -> `Requested_range_not_satisfiable
# 87 "cohttp/http_common.ml"
  | 417 -> `Expectation_failed
# 88 "cohttp/http_common.ml"
  | 500 -> `Internal_server_error
# 89 "cohttp/http_common.ml"
  | 501 -> `Not_implemented
# 90 "cohttp/http_common.ml"
  | 502 -> `Bad_gateway
# 91 "cohttp/http_common.ml"
  | 503 -> `Service_unavailable
# 92 "cohttp/http_common.ml"
  | 504 -> `Gateway_time_out
# 93 "cohttp/http_common.ml"
  | 505 -> `HTTP_version_not_supported
# 94 "cohttp/http_common.ml"
  | invalid_code -> raise (Invalid_code invalid_code)
# 95 "cohttp/http_common.ml"

# 96 "cohttp/http_common.ml"
let code_of_status = function
# 97 "cohttp/http_common.ml"
  | `Continue -> 100
# 98 "cohttp/http_common.ml"
  | `Switching_protocols -> 101
# 99 "cohttp/http_common.ml"
  | `OK -> 200
# 100 "cohttp/http_common.ml"
  | `Created -> 201
# 101 "cohttp/http_common.ml"
  | `Accepted -> 202
# 102 "cohttp/http_common.ml"
  | `Non_authoritative_information -> 203
# 103 "cohttp/http_common.ml"
  | `No_content -> 204
# 104 "cohttp/http_common.ml"
  | `Reset_content -> 205
# 105 "cohttp/http_common.ml"
  | `Partial_content -> 206
# 106 "cohttp/http_common.ml"
  | `Multiple_choices -> 300
# 107 "cohttp/http_common.ml"
  | `Moved_permanently -> 301
# 108 "cohttp/http_common.ml"
  | `Found -> 302
# 109 "cohttp/http_common.ml"
  | `See_other -> 303
# 110 "cohttp/http_common.ml"
  | `Not_modified -> 304
# 111 "cohttp/http_common.ml"
  | `Use_proxy -> 305
# 112 "cohttp/http_common.ml"
  | `Temporary_redirect -> 307
# 113 "cohttp/http_common.ml"
  | `Bad_request -> 400
# 114 "cohttp/http_common.ml"
  | `Unauthorized -> 401
# 115 "cohttp/http_common.ml"
  | `Payment_required -> 402
# 116 "cohttp/http_common.ml"
  | `Forbidden -> 403
# 117 "cohttp/http_common.ml"
  | `Not_found -> 404
# 118 "cohttp/http_common.ml"
  | `Method_not_allowed -> 405
# 119 "cohttp/http_common.ml"
  | `Not_acceptable -> 406
# 120 "cohttp/http_common.ml"
  | `Proxy_authentication_required -> 407
# 121 "cohttp/http_common.ml"
  | `Request_time_out -> 408
# 122 "cohttp/http_common.ml"
  | `Conflict -> 409
# 123 "cohttp/http_common.ml"
  | `Gone -> 410
# 124 "cohttp/http_common.ml"
  | `Length_required -> 411
# 125 "cohttp/http_common.ml"
  | `Precondition_failed -> 412
# 126 "cohttp/http_common.ml"
  | `Request_entity_too_large -> 413
# 127 "cohttp/http_common.ml"
  | `Request_URI_too_large -> 414
# 128 "cohttp/http_common.ml"
  | `Unsupported_media_type -> 415
# 129 "cohttp/http_common.ml"
  | `Requested_range_not_satisfiable -> 416
# 130 "cohttp/http_common.ml"
  | `Expectation_failed -> 417
# 131 "cohttp/http_common.ml"
  | `Internal_server_error -> 500
# 132 "cohttp/http_common.ml"
  | `Not_implemented -> 501
# 133 "cohttp/http_common.ml"
  | `Bad_gateway -> 502
# 134 "cohttp/http_common.ml"
  | `Service_unavailable -> 503
# 135 "cohttp/http_common.ml"
  | `Gateway_time_out -> 504
# 136 "cohttp/http_common.ml"
  | `HTTP_version_not_supported -> 505
# 137 "cohttp/http_common.ml"

# 138 "cohttp/http_common.ml"
let is_informational code =
# 139 "cohttp/http_common.ml"
  match status_of_code code with
# 140 "cohttp/http_common.ml"
  | #informational_status -> true
# 141 "cohttp/http_common.ml"
  | _ -> false
# 142 "cohttp/http_common.ml"

# 143 "cohttp/http_common.ml"
let is_success code =
# 144 "cohttp/http_common.ml"
  match status_of_code code with
# 145 "cohttp/http_common.ml"
  | #success_status -> true
# 146 "cohttp/http_common.ml"
  | _ -> false
# 147 "cohttp/http_common.ml"

# 148 "cohttp/http_common.ml"
let is_redirection code =
# 149 "cohttp/http_common.ml"
  match status_of_code code with
# 150 "cohttp/http_common.ml"
  | #redirection_status -> true
# 151 "cohttp/http_common.ml"
  | _ -> false
# 152 "cohttp/http_common.ml"

# 153 "cohttp/http_common.ml"
let is_client_error code =
# 154 "cohttp/http_common.ml"
  match status_of_code code with
# 155 "cohttp/http_common.ml"
  | #client_error_status -> true
# 156 "cohttp/http_common.ml"
  | _ -> false
# 157 "cohttp/http_common.ml"

# 158 "cohttp/http_common.ml"
let is_server_error code =
# 159 "cohttp/http_common.ml"
  match status_of_code code with
# 160 "cohttp/http_common.ml"
  | #server_error_status -> true
# 161 "cohttp/http_common.ml"
  | _ -> false
# 162 "cohttp/http_common.ml"

# 163 "cohttp/http_common.ml"
let is_error code = is_client_error code || is_server_error code
# 164 "cohttp/http_common.ml"

# 165 "cohttp/http_common.ml"
end
module Http_parser_sanity : sig
# 1 "cohttp/http_parser_sanity.mli"

# 2 "cohttp/http_parser_sanity.mli"
(*
# 3 "cohttp/http_parser_sanity.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_parser_sanity.mli"

# 5 "cohttp/http_parser_sanity.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_parser_sanity.mli"

# 7 "cohttp/http_parser_sanity.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_parser_sanity.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_parser_sanity.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_parser_sanity.mli"

# 11 "cohttp/http_parser_sanity.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_parser_sanity.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_parser_sanity.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_parser_sanity.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_parser_sanity.mli"

# 16 "cohttp/http_parser_sanity.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_parser_sanity.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_parser_sanity.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_parser_sanity.mli"
  USA
# 20 "cohttp/http_parser_sanity.mli"
*)
# 21 "cohttp/http_parser_sanity.mli"

# 22 "cohttp/http_parser_sanity.mli"
(** Sanity test functions related to HTTP message parsing *)
# 23 "cohttp/http_parser_sanity.mli"

# 24 "cohttp/http_parser_sanity.mli"
  (** remove heading and/or trailing LWS sequences as per RFC2616 *)
# 25 "cohttp/http_parser_sanity.mli"
val normalize_header_value: string -> string
# 26 "cohttp/http_parser_sanity.mli"

# 27 "cohttp/http_parser_sanity.mli"
end = struct
# 1 "cohttp/http_parser_sanity.ml"

# 2 "cohttp/http_parser_sanity.ml"
(*
# 3 "cohttp/http_parser_sanity.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_parser_sanity.ml"

# 5 "cohttp/http_parser_sanity.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_parser_sanity.ml"

# 7 "cohttp/http_parser_sanity.ml"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_parser_sanity.ml"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_parser_sanity.ml"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_parser_sanity.ml"

# 11 "cohttp/http_parser_sanity.ml"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_parser_sanity.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_parser_sanity.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_parser_sanity.ml"
  GNU Library General Public License for more details.
# 15 "cohttp/http_parser_sanity.ml"

# 16 "cohttp/http_parser_sanity.ml"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_parser_sanity.ml"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_parser_sanity.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_parser_sanity.ml"
  USA
# 20 "cohttp/http_parser_sanity.ml"
*)
# 21 "cohttp/http_parser_sanity.ml"

# 22 "cohttp/http_parser_sanity.ml"
open Printf
# 23 "cohttp/http_parser_sanity.ml"

# 24 "cohttp/http_parser_sanity.ml"
open Http_types
# 25 "cohttp/http_parser_sanity.ml"
open Http_constants
# 26 "cohttp/http_parser_sanity.ml"

# 27 "cohttp/http_parser_sanity.ml"
let lws_RE_raw = "(\r\n)?[ \t]"
# 28 "cohttp/http_parser_sanity.ml"
let heading_lws_RE = Str.regexp "^\\(\r\n\\)?[ \t]*"
# 29 "cohttp/http_parser_sanity.ml"
let trailing_lws_RE = Str.regexp "\\(\r\n\\)?[ \t]*$"
# 30 "cohttp/http_parser_sanity.ml"

# 31 "cohttp/http_parser_sanity.ml"
let normalize_header_value s =
# 32 "cohttp/http_parser_sanity.ml"
  Str.replace_first trailing_lws_RE "" (Str.replace_first heading_lws_RE "" s)
# 33 "cohttp/http_parser_sanity.ml"
end
module Http_parser : sig
# 1 "cohttp/http_parser.mli"

# 2 "cohttp/http_parser.mli"
(*
# 3 "cohttp/http_parser.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_parser.mli"

# 5 "cohttp/http_parser.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_parser.mli"

# 7 "cohttp/http_parser.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_parser.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_parser.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_parser.mli"

# 11 "cohttp/http_parser.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_parser.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_parser.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_parser.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_parser.mli"

# 16 "cohttp/http_parser.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_parser.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_parser.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_parser.mli"
  USA
# 20 "cohttp/http_parser.mli"
*)
# 21 "cohttp/http_parser.mli"

# 22 "cohttp/http_parser.mli"
(** HTTP messages parsing *)
# 23 "cohttp/http_parser.mli"

# 24 "cohttp/http_parser.mli"
open Http_types;;
# 25 "cohttp/http_parser.mli"

# 26 "cohttp/http_parser.mli"
  (** given an HTTP like query string (e.g. "name1=value1&name2=value2&...")
# 27 "cohttp/http_parser.mli"
  @return a list of pairs [("name1", "value1"); ("name2", "value2")]
# 28 "cohttp/http_parser.mli"
  @raise Malformed_query if the string isn't a valid query string
# 29 "cohttp/http_parser.mli"
  @raise Malformed_query_part if some piece of the query isn't valid
# 30 "cohttp/http_parser.mli"
  *)
# 31 "cohttp/http_parser.mli"
val split_query_params: string -> (string * string) list
# 32 "cohttp/http_parser.mli"

# 33 "cohttp/http_parser.mli"
  (** parse 1st line of an HTTP request
# 34 "cohttp/http_parser.mli"
  @param inchan input channel from which parse request
# 35 "cohttp/http_parser.mli"
  @return a triple meth * url * version, meth is the HTTP method invoked, url is
# 36 "cohttp/http_parser.mli"
  the requested url, version is the HTTP version specified or None if no version
# 37 "cohttp/http_parser.mli"
  was specified
# 38 "cohttp/http_parser.mli"
  @raise Malformed_request if request 1st linst isn't well formed
# 39 "cohttp/http_parser.mli"
  @raise Malformed_request_URI if requested URI isn't well formed *)
# 40 "cohttp/http_parser.mli"
val parse_request_fst_line: OS.Flow.t -> (meth * Http_url.t * version) Lwt.t
# 41 "cohttp/http_parser.mli"

# 42 "cohttp/http_parser.mli"
  (** parse 1st line of an HTTP response
# 43 "cohttp/http_parser.mli"
   * @param inchan input channel from which parse response
# 44 "cohttp/http_parser.mli"
   * @raise Malformed_response if first line isn't well formed
# 45 "cohttp/http_parser.mli"
  *)
# 46 "cohttp/http_parser.mli"
val parse_response_fst_line: OS.Flow.t -> (version * status) Lwt.t
# 47 "cohttp/http_parser.mli"

# 48 "cohttp/http_parser.mli"
  (** parse HTTP GET parameters from an URL; paramater which were passed with no
# 49 "cohttp/http_parser.mli"
  value (like 'x' in "/foo.cgi?a=10&x=&c=9") are returned associated with the
# 50 "cohttp/http_parser.mli"
  empty ("") string.
# 51 "cohttp/http_parser.mli"
  @return a list of pairs param_name * param_value *)
# 52 "cohttp/http_parser.mli"
val parse_query_get_params: Http_url.t -> (string * string) list
# 53 "cohttp/http_parser.mli"

# 54 "cohttp/http_parser.mli"
  (** parse the base path (removing query string, fragment, ....) from an URL *)
# 55 "cohttp/http_parser.mli"
val parse_path: Http_url.t -> string
# 56 "cohttp/http_parser.mli"

# 57 "cohttp/http_parser.mli"
  (** parse HTTP headers. Consumes also trailing CRLF at the end of header list
# 58 "cohttp/http_parser.mli"
  @param inchan input channel from which parse headers
# 59 "cohttp/http_parser.mli"
  @return a list of pairs header_name * header_value
# 60 "cohttp/http_parser.mli"
  @raise Invalid_header if a not well formed header is encountered *)
# 61 "cohttp/http_parser.mli"
val parse_headers: OS.Flow.t -> ((string * string) list) Lwt.t
# 62 "cohttp/http_parser.mli"

# 63 "cohttp/http_parser.mli"
  (** given an input channel, reads from it a GET HTTP request and
# 64 "cohttp/http_parser.mli"
  @return a pair <path, query_params> where path is a string representing the
# 65 "cohttp/http_parser.mli"
  requested path and query_params is a list of pairs <name, value> (the GET
# 66 "cohttp/http_parser.mli"
  parameters) *)
# 67 "cohttp/http_parser.mli"
val parse_request: OS.Flow.t -> (string * (string * string) list) Lwt.t
# 68 "cohttp/http_parser.mli"

# 69 "cohttp/http_parser.mli"
end = struct
# 1 "cohttp/http_parser.ml"
(*
# 2 "cohttp/http_parser.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_parser.ml"

# 4 "cohttp/http_parser.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_parser.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 6 "cohttp/http_parser.ml"

# 7 "cohttp/http_parser.ml"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_parser.ml"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_parser.ml"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_parser.ml"

# 11 "cohttp/http_parser.ml"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_parser.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_parser.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_parser.ml"
  GNU Library General Public License for more details.
# 15 "cohttp/http_parser.ml"

# 16 "cohttp/http_parser.ml"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_parser.ml"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_parser.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_parser.ml"
  USA
# 20 "cohttp/http_parser.ml"
*)
# 21 "cohttp/http_parser.ml"

# 22 "cohttp/http_parser.ml"
open Printf
# 23 "cohttp/http_parser.ml"
open Lwt
# 24 "cohttp/http_parser.ml"

# 25 "cohttp/http_parser.ml"
open Http_common
# 26 "cohttp/http_parser.ml"
open Http_types
# 27 "cohttp/http_parser.ml"
open Http_constants
# 28 "cohttp/http_parser.ml"

# 29 "cohttp/http_parser.ml"
let bindings_sep, binding_sep, pieces_sep, header_sep =
# 30 "cohttp/http_parser.ml"
  Str.(regexp_string "&", regexp_string "=", 
# 31 "cohttp/http_parser.ml"
       regexp_string " ", regexp_string ":" )
# 32 "cohttp/http_parser.ml"

# 33 "cohttp/http_parser.ml"
let header_RE = Str.regexp "([^:]*):(.*)"
# 34 "cohttp/http_parser.ml"

# 35 "cohttp/http_parser.ml"
let url_decode url = Http_url.decode url
# 36 "cohttp/http_parser.ml"

# 37 "cohttp/http_parser.ml"
let split_query_params query =
# 38 "cohttp/http_parser.ml"
  let bindings = Str.split bindings_sep query in
# 39 "cohttp/http_parser.ml"
  match bindings with
# 40 "cohttp/http_parser.ml"
  | [] -> raise (Malformed_query query)
# 41 "cohttp/http_parser.ml"
  | bindings ->
# 42 "cohttp/http_parser.ml"
      List.map
# 43 "cohttp/http_parser.ml"
        (fun binding ->
# 44 "cohttp/http_parser.ml"
          match Str.split binding_sep binding with
# 45 "cohttp/http_parser.ml"
          | [ ""; b ] -> (* '=b' *)
# 46 "cohttp/http_parser.ml"
              raise (Malformed_query_part (binding, query))
# 47 "cohttp/http_parser.ml"
          | [ a; b ]  -> (* 'a=b' *) (url_decode a, url_decode b)
# 48 "cohttp/http_parser.ml"
          | [ a ]     -> (* 'a=' || 'a' *) (url_decode a, "")
# 49 "cohttp/http_parser.ml"
          | _ -> raise (Malformed_query_part (binding, query)))
# 50 "cohttp/http_parser.ml"
        bindings
# 51 "cohttp/http_parser.ml"

# 52 "cohttp/http_parser.ml"
let debug_dump_request path params =
# 53 "cohttp/http_parser.ml"
  debug_print
# 54 "cohttp/http_parser.ml"
    (sprintf
# 55 "cohttp/http_parser.ml"
      "recevied request; path: %s; params: %s"
# 56 "cohttp/http_parser.ml"
      path
# 57 "cohttp/http_parser.ml"
      (String.concat ", " (List.map (fun (n, v) -> n ^ "=" ^ v) params)))
# 58 "cohttp/http_parser.ml"

# 59 "cohttp/http_parser.ml"
let parse_request_fst_line ic =
# 60 "cohttp/http_parser.ml"
  debug_print "parse_request_fst_line";
# 61 "cohttp/http_parser.ml"
  lwt request_line = OS.Flow.read_line ic in
# 62 "cohttp/http_parser.ml"
  debug_print (sprintf "HTTP request line (not yet parsed): %s" request_line);
# 63 "cohttp/http_parser.ml"
  try_lwt begin
# 64 "cohttp/http_parser.ml"
    match Str.split pieces_sep request_line with
# 65 "cohttp/http_parser.ml"
      | [ meth_raw; uri_raw; http_version_raw ] ->
# 66 "cohttp/http_parser.ml"
          return (method_of_string meth_raw,
# 67 "cohttp/http_parser.ml"
		  Http_url.of_string uri_raw,
# 68 "cohttp/http_parser.ml"
		  version_of_string http_version_raw)
# 69 "cohttp/http_parser.ml"
      | _ -> fail (Malformed_request request_line)
# 70 "cohttp/http_parser.ml"
  end with | Malformed_URL url -> fail (Malformed_request_URI url)
# 71 "cohttp/http_parser.ml"

# 72 "cohttp/http_parser.ml"
let parse_response_fst_line ic =
# 73 "cohttp/http_parser.ml"
  lwt response_line = OS.Flow.read_line ic in
# 74 "cohttp/http_parser.ml"
  debug_print (sprintf "HTTP response line (not yet parsed): %s" response_line);
# 75 "cohttp/http_parser.ml"
  try_lwt
# 76 "cohttp/http_parser.ml"
    (match Str.split pieces_sep response_line with
# 77 "cohttp/http_parser.ml"
    | version_raw :: code_raw :: _ ->
# 78 "cohttp/http_parser.ml"
        debug_print (Printf.sprintf "version_raw=%s; code_raw=%s" version_raw code_raw);
# 79 "cohttp/http_parser.ml"
        return (version_of_string version_raw,      (* method *)
# 80 "cohttp/http_parser.ml"
        status_of_code (int_of_string code_raw))    (* status *)
# 81 "cohttp/http_parser.ml"
    | _ ->
# 82 "cohttp/http_parser.ml"
		debug_print "Malformed_response";
# 83 "cohttp/http_parser.ml"
		fail (Malformed_response response_line))
# 84 "cohttp/http_parser.ml"
  with 
# 85 "cohttp/http_parser.ml"
  | Malformed_URL _ | Invalid_code _ | Failure "int_of_string" ->
# 86 "cohttp/http_parser.ml"
     fail (Malformed_response response_line)
# 87 "cohttp/http_parser.ml"
  | e -> fail e
# 88 "cohttp/http_parser.ml"

# 89 "cohttp/http_parser.ml"
let parse_path uri = match Http_url.path uri with None -> "/" | Some x -> x
# 90 "cohttp/http_parser.ml"

# 91 "cohttp/http_parser.ml"
let parse_query_get_params uri =
# 92 "cohttp/http_parser.ml"
  try (* act on HTTP encoded URIs *)
# 93 "cohttp/http_parser.ml"
    match Http_url.query uri with None -> [] | Some x -> split_query_params x
# 94 "cohttp/http_parser.ml"
  with Not_found -> []
# 95 "cohttp/http_parser.ml"

# 96 "cohttp/http_parser.ml"
let parse_headers ic =
# 97 "cohttp/http_parser.ml"
  (* consume also trailing "^\r\n$" line *)
# 98 "cohttp/http_parser.ml"
  let rec parse_headers' headers =
# 99 "cohttp/http_parser.ml"
    OS.Flow.read_line ic >>= function
# 100 "cohttp/http_parser.ml"
    | "" -> return (List.rev headers)
# 101 "cohttp/http_parser.ml"
    | line -> begin
# 102 "cohttp/http_parser.ml"
        match Str.(bounded_split (regexp_string ":") line 2) with
# 103 "cohttp/http_parser.ml"
        | [header; value] ->
# 104 "cohttp/http_parser.ml"
            lwt norm_value =
# 105 "cohttp/http_parser.ml"
              try_lwt 
# 106 "cohttp/http_parser.ml"
                return (Http_parser_sanity.normalize_header_value value)
# 107 "cohttp/http_parser.ml"
              with _ -> return "" in
# 108 "cohttp/http_parser.ml"
            parse_headers' ((header, value) :: headers)
# 109 "cohttp/http_parser.ml"
        | _ -> fail (Invalid_header line) 
# 110 "cohttp/http_parser.ml"
      end
# 111 "cohttp/http_parser.ml"
  in
# 112 "cohttp/http_parser.ml"
  parse_headers' []
# 113 "cohttp/http_parser.ml"

# 114 "cohttp/http_parser.ml"
let parse_request ic =
# 115 "cohttp/http_parser.ml"
  debug_print "parse_request";
# 116 "cohttp/http_parser.ml"
  lwt (meth, uri, version) = parse_request_fst_line ic in
# 117 "cohttp/http_parser.ml"
  let path = parse_path uri in
# 118 "cohttp/http_parser.ml"
  let query_get_params = parse_query_get_params uri in
# 119 "cohttp/http_parser.ml"
  debug_dump_request path query_get_params;
# 120 "cohttp/http_parser.ml"
  return (path, query_get_params)
# 121 "cohttp/http_parser.ml"

# 122 "cohttp/http_parser.ml"
end
module Http_user_agent : sig
# 1 "cohttp/http_user_agent.mli"
(*
# 2 "cohttp/http_user_agent.mli"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_user_agent.mli"

# 4 "cohttp/http_user_agent.mli"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_user_agent.mli"
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
# 6 "cohttp/http_user_agent.mli"

# 7 "cohttp/http_user_agent.mli"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_user_agent.mli"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_user_agent.mli"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_user_agent.mli"

# 11 "cohttp/http_user_agent.mli"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_user_agent.mli"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_user_agent.mli"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_user_agent.mli"
  GNU Library General Public License for more details.
# 15 "cohttp/http_user_agent.mli"

# 16 "cohttp/http_user_agent.mli"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_user_agent.mli"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_user_agent.mli"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_user_agent.mli"
  USA
# 20 "cohttp/http_user_agent.mli"
*)
# 21 "cohttp/http_user_agent.mli"

# 22 "cohttp/http_user_agent.mli"
(** Minimal implementation of an HTTP 1.0/1.1 client. Interface is similar to
# 23 "cohttp/http_user_agent.mli"
    Gerd Stoplmann's Http_client module. Implementation is simpler and doesn't
# 24 "cohttp/http_user_agent.mli"
    handle HTTP redirection, proxies, ecc. The only reason for the existence of
# 25 "cohttp/http_user_agent.mli"
    this module is for performances and incremental elaboration of response's
# 26 "cohttp/http_user_agent.mli"
    bodies *)
# 27 "cohttp/http_user_agent.mli"

# 28 "cohttp/http_user_agent.mli"
type headers = (string * string) list
# 29 "cohttp/http_user_agent.mli"

# 30 "cohttp/http_user_agent.mli"
type tcp_error_source = Connect | Read | Write
# 31 "cohttp/http_user_agent.mli"
exception Tcp_error of tcp_error_source * exn
# 32 "cohttp/http_user_agent.mli"
exception Http_error of (int * headers * string)  (* code, headers, body *)
# 33 "cohttp/http_user_agent.mli"

# 34 "cohttp/http_user_agent.mli"
  (**
# 35 "cohttp/http_user_agent.mli"
     @param headers optional overriding headers
# 36 "cohttp/http_user_agent.mli"
     @param url an HTTP url
# 37 "cohttp/http_user_agent.mli"
     @return HTTP response's body
# 38 "cohttp/http_user_agent.mli"
     @raise Http_error when response code <> 200 *)
# 39 "cohttp/http_user_agent.mli"
val get : ?headers:headers -> string -> (headers * string) Lwt.t
# 40 "cohttp/http_user_agent.mli"

# 41 "cohttp/http_user_agent.mli"
  (**
# 42 "cohttp/http_user_agent.mli"
     @param headers optional overriding headers
# 43 "cohttp/http_user_agent.mli"
     @param url an HTTP url
# 44 "cohttp/http_user_agent.mli"
     @return HTTP HEAD raw response
# 45 "cohttp/http_user_agent.mli"
     @raise Http_error when response code <> 200 *)
# 46 "cohttp/http_user_agent.mli"
val head : ?headers:headers -> string -> (headers * string) Lwt.t
# 47 "cohttp/http_user_agent.mli"

# 48 "cohttp/http_user_agent.mli"
  (**
# 49 "cohttp/http_user_agent.mli"
     @param headers optional overriding headers
# 50 "cohttp/http_user_agent.mli"
     @param body optional message
# 51 "cohttp/http_user_agent.mli"
     @param url an HTTP url
# 52 "cohttp/http_user_agent.mli"
     @return HTTP HEAD raw response
# 53 "cohttp/http_user_agent.mli"
     @raise Http_error when response code <> 200 *)
# 54 "cohttp/http_user_agent.mli"
val post : ?headers:headers -> ?body:string -> string -> (headers * string) Lwt.t
# 55 "cohttp/http_user_agent.mli"

# 56 "cohttp/http_user_agent.mli"
end = struct
# 1 "cohttp/http_user_agent.ml"
(*
# 2 "cohttp/http_user_agent.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_user_agent.ml"

# 4 "cohttp/http_user_agent.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_user_agent.ml"
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
# 6 "cohttp/http_user_agent.ml"

# 7 "cohttp/http_user_agent.ml"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_user_agent.ml"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_user_agent.ml"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_user_agent.ml"

# 11 "cohttp/http_user_agent.ml"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_user_agent.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_user_agent.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_user_agent.ml"
  GNU Library General Public License for more details.
# 15 "cohttp/http_user_agent.ml"

# 16 "cohttp/http_user_agent.ml"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_user_agent.ml"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_user_agent.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_user_agent.ml"
  USA
# 20 "cohttp/http_user_agent.ml"
*)
# 21 "cohttp/http_user_agent.ml"

# 22 "cohttp/http_user_agent.ml"
open Printf
# 23 "cohttp/http_user_agent.ml"
open Http_common
# 24 "cohttp/http_user_agent.ml"
open Lwt
# 25 "cohttp/http_user_agent.ml"

# 26 "cohttp/http_user_agent.ml"
type headers = (string * string) list
# 27 "cohttp/http_user_agent.ml"

# 28 "cohttp/http_user_agent.ml"
type tcp_error_source = Connect | Read | Write
# 29 "cohttp/http_user_agent.ml"
exception Tcp_error of tcp_error_source * exn
# 30 "cohttp/http_user_agent.ml"
exception Http_error of (int * headers * string)  (* code, body *)
# 31 "cohttp/http_user_agent.ml"
exception Invalid_url
# 32 "cohttp/http_user_agent.ml"

# 33 "cohttp/http_user_agent.ml"
let url_RE = Str.regexp "^[hH][tT][tT][pP]://\\([a-zA-Z.-]+\\)\\(:[0-9]+\\)?\\(/.*\\)?"
# 34 "cohttp/http_user_agent.ml"

# 35 "cohttp/http_user_agent.ml"
let tcp_bufsiz = 4096 (* for TCP I/O *)
# 36 "cohttp/http_user_agent.ml"

# 37 "cohttp/http_user_agent.ml"
let parse_url url =
# 38 "cohttp/http_user_agent.ml"
  try
# 39 "cohttp/http_user_agent.ml"
    if not (Str.string_match url_RE url 0) then raise Invalid_url;
# 40 "cohttp/http_user_agent.ml"
    let host = Str.matched_group 1 url in
# 41 "cohttp/http_user_agent.ml"
    let port = try
# 42 "cohttp/http_user_agent.ml"
        let port_s = Str.matched_group 2 url in
# 43 "cohttp/http_user_agent.ml"
        int_of_string (String.sub port_s 1 (String.length port_s - 1))
# 44 "cohttp/http_user_agent.ml"
      with _ -> 80 in
# 45 "cohttp/http_user_agent.ml"
    let path = try Str.matched_group 3 url with Not_found -> "/" in
# 46 "cohttp/http_user_agent.ml"
    (host, port, path)
# 47 "cohttp/http_user_agent.ml"
  with exc ->
# 48 "cohttp/http_user_agent.ml"
    failwith
# 49 "cohttp/http_user_agent.ml"
      (sprintf "Can't parse url: %s (exception: %s)"
# 50 "cohttp/http_user_agent.ml"
        url (Printexc.to_string exc))
# 51 "cohttp/http_user_agent.ml"

# 52 "cohttp/http_user_agent.ml"
let build_req_string headers meth address path body =
# 53 "cohttp/http_user_agent.ml"
  let content_type = ("Content-Type", "application/x-www-form-urlencoded") in
# 54 "cohttp/http_user_agent.ml"
  let content_length s = ("Content-Length", string_of_int (String.length s)) in
# 55 "cohttp/http_user_agent.ml"
  let body, headers = match body with
# 56 "cohttp/http_user_agent.ml"
    | None -> "", headers
# 57 "cohttp/http_user_agent.ml"
    | Some s -> s, content_type::(content_length s)::headers in
# 58 "cohttp/http_user_agent.ml"
  let headers = ("Host", address)::headers in
# 59 "cohttp/http_user_agent.ml"
  let hdrcnt = List.length headers in
# 60 "cohttp/http_user_agent.ml"
  let add_header ht (n, v) = (Hashtbl.replace ht n v; ht) in
# 61 "cohttp/http_user_agent.ml"
  let hdrht = List.fold_left add_header (Hashtbl.create hdrcnt) headers in
# 62 "cohttp/http_user_agent.ml"
  let serialize_header name value prev =
# 63 "cohttp/http_user_agent.ml"
    sprintf "%s\r\n%s: %s" prev name value in
# 64 "cohttp/http_user_agent.ml"
  let hdrst = Hashtbl.fold serialize_header hdrht "" in
# 65 "cohttp/http_user_agent.ml"
    sprintf "%s %s HTTP/1.0%s\r\n\r\n%s" meth path hdrst body
# 66 "cohttp/http_user_agent.ml"

# 67 "cohttp/http_user_agent.ml"
let request outchan headers meth body (address, _, path) =
# 68 "cohttp/http_user_agent.ml"
  let headers = match headers with None -> [] | Some hs -> hs in
# 69 "cohttp/http_user_agent.ml"
    OS.Flow.write_all outchan (build_req_string headers meth address path body)
# 70 "cohttp/http_user_agent.ml"

# 71 "cohttp/http_user_agent.ml"
let read inchan =
# 72 "cohttp/http_user_agent.ml"
  lwt (_, status) = Http_parser.parse_response_fst_line inchan in
# 73 "cohttp/http_user_agent.ml"
  lwt headers = Http_parser.parse_headers inchan in
# 74 "cohttp/http_user_agent.ml"
  let headers = List.map (fun (h, v) -> (String.lowercase h, v)) headers in
# 75 "cohttp/http_user_agent.ml"
  lwt resp = OS.Flow.read_all inchan in
# 76 "cohttp/http_user_agent.ml"
    match code_of_status status with
# 77 "cohttp/http_user_agent.ml"
      | 200 -> return (headers, resp)
# 78 "cohttp/http_user_agent.ml"
      | code -> fail (Http_error (code, headers, resp))
# 79 "cohttp/http_user_agent.ml"

# 80 "cohttp/http_user_agent.ml"
let connect (address, port, _) iofn =
# 81 "cohttp/http_user_agent.ml"
  lwt sockaddr = Http_misc.build_sockaddr (address, port) in
# 82 "cohttp/http_user_agent.ml"
  OS.Flow.with_connection sockaddr iofn
# 83 "cohttp/http_user_agent.ml"
    
# 84 "cohttp/http_user_agent.ml"
let call headers kind body url =
# 85 "cohttp/http_user_agent.ml"
  let meth = match kind with
# 86 "cohttp/http_user_agent.ml"
    | `GET -> "GET"
# 87 "cohttp/http_user_agent.ml"
    | `HEAD -> "HEAD"
# 88 "cohttp/http_user_agent.ml"
    | `POST -> "POST" in
# 89 "cohttp/http_user_agent.ml"
  let endp = parse_url url in
# 90 "cohttp/http_user_agent.ml"
    try_lwt connect endp
# 91 "cohttp/http_user_agent.ml"
      (fun t ->
# 92 "cohttp/http_user_agent.ml"
	 (try_lwt request t headers meth body endp
# 93 "cohttp/http_user_agent.ml"
	  with exn -> fail (Tcp_error (Write, exn))
# 94 "cohttp/http_user_agent.ml"
	 ) >> (try_lwt read t
# 95 "cohttp/http_user_agent.ml"
	       with
# 96 "cohttp/http_user_agent.ml"
		 | (Http_error _) as e -> fail e
# 97 "cohttp/http_user_agent.ml"
		 | exn -> fail (Tcp_error (Read, exn))
# 98 "cohttp/http_user_agent.ml"
	      ))
# 99 "cohttp/http_user_agent.ml"
    with
# 100 "cohttp/http_user_agent.ml"
      | (Tcp_error _ | Http_error _) as e -> fail e
# 101 "cohttp/http_user_agent.ml"
      | exn -> fail (Tcp_error (Connect, exn))
# 102 "cohttp/http_user_agent.ml"

# 103 "cohttp/http_user_agent.ml"
let head ?headers url = call headers `HEAD None url
# 104 "cohttp/http_user_agent.ml"
let get  ?headers url = call headers `GET None url
# 105 "cohttp/http_user_agent.ml"
let post ?headers ?body url = call headers `POST body url
# 106 "cohttp/http_user_agent.ml"
end
module Http_message : sig
# 1 "cohttp/http_message.mli"
open Mlnet.Types
# 2 "cohttp/http_message.mli"

# 3 "cohttp/http_message.mli"
type contents =
# 4 "cohttp/http_message.mli"
    [ `Buffer of Buffer.t
# 5 "cohttp/http_message.mli"
    | `String of string
# 6 "cohttp/http_message.mli"
    | `Inchan of int64 * OS.Flow.t * unit Lwt.u
# 7 "cohttp/http_message.mli"
    ]
# 8 "cohttp/http_message.mli"
type message
# 9 "cohttp/http_message.mli"
val body : message -> contents list
# 10 "cohttp/http_message.mli"
val body_size : contents list -> int64
# 11 "cohttp/http_message.mli"
val string_of_body : contents list -> string Lwt.t
# 12 "cohttp/http_message.mli"
val set_body : message -> contents -> unit
# 13 "cohttp/http_message.mli"
val add_body : message -> contents -> unit
# 14 "cohttp/http_message.mli"
val add_header : message -> name:string -> value:string -> unit
# 15 "cohttp/http_message.mli"
val add_headers : message -> (string * string) list -> unit
# 16 "cohttp/http_message.mli"
val replace_header : message -> name:string -> value:string -> unit
# 17 "cohttp/http_message.mli"
val replace_headers : message -> (string * string) list -> unit
# 18 "cohttp/http_message.mli"
val remove_header : message -> name:string -> unit
# 19 "cohttp/http_message.mli"
val has_header : message -> name:string -> bool
# 20 "cohttp/http_message.mli"
val header : message -> name:string -> string list
# 21 "cohttp/http_message.mli"
val headers : message -> (string * string) list
# 22 "cohttp/http_message.mli"
val client_addr : message -> string
# 23 "cohttp/http_message.mli"
val server_addr : message -> string
# 24 "cohttp/http_message.mli"
val client_port : message -> int
# 25 "cohttp/http_message.mli"
val server_port : message -> int
# 26 "cohttp/http_message.mli"
val version : message -> Http_types.version
# 27 "cohttp/http_message.mli"
val init :
# 28 "cohttp/http_message.mli"
  body:contents list ->
# 29 "cohttp/http_message.mli"
  headers:(string * string) list ->
# 30 "cohttp/http_message.mli"
  version:Http_types.version ->
# 31 "cohttp/http_message.mli"
  clisockaddr:sockaddr -> srvsockaddr:sockaddr -> message
# 32 "cohttp/http_message.mli"
val serialize :
# 33 "cohttp/http_message.mli"
  message ->
# 34 "cohttp/http_message.mli"
  'a -> ('a -> string -> unit Lwt.t) -> ('a -> string -> int -> int -> unit Lwt.t) ->
# 35 "cohttp/http_message.mli"
  fstLineToString:string -> unit Lwt.t
# 36 "cohttp/http_message.mli"
val serialize_to_output_channel :
# 37 "cohttp/http_message.mli"
  message -> OS.Flow.t -> fstLineToString:string -> unit Lwt.t
# 38 "cohttp/http_message.mli"
val serialize_to_stream :
# 39 "cohttp/http_message.mli"
  message -> fstLineToString:string -> string Lwt_stream.t
# 40 "cohttp/http_message.mli"
end = struct
# 1 "cohttp/http_message.ml"
(*
# 2 "cohttp/http_message.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_message.ml"

# 4 "cohttp/http_message.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_message.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 6 "cohttp/http_message.ml"
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
# 7 "cohttp/http_message.ml"

# 8 "cohttp/http_message.ml"
  This program is free software; you can redistribute it and/or modify
# 9 "cohttp/http_message.ml"
  it under the terms of the GNU Library General Public License as
# 10 "cohttp/http_message.ml"
  published by the Free Software Foundation, version 2.
# 11 "cohttp/http_message.ml"

# 12 "cohttp/http_message.ml"
  This program is distributed in the hope that it will be useful,
# 13 "cohttp/http_message.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 14 "cohttp/http_message.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 15 "cohttp/http_message.ml"
  GNU Library General Public License for more details.
# 16 "cohttp/http_message.ml"

# 17 "cohttp/http_message.ml"
  You should have received a copy of the GNU Library General Public
# 18 "cohttp/http_message.ml"
  License along with this program; if not, write to the Free Software
# 19 "cohttp/http_message.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 20 "cohttp/http_message.ml"
  USA
# 21 "cohttp/http_message.ml"
*)
# 22 "cohttp/http_message.ml"
open Http_common
# 23 "cohttp/http_message.ml"
open Http_constants
# 24 "cohttp/http_message.ml"
open Http_types
# 25 "cohttp/http_message.ml"
open Printf
# 26 "cohttp/http_message.ml"
open Lwt
# 27 "cohttp/http_message.ml"

# 28 "cohttp/http_message.ml"
  (* remove all bindings of 'name' from hashtbl 'tbl' *)
# 29 "cohttp/http_message.ml"
let rec hashtbl_remove_all tbl name =
# 30 "cohttp/http_message.ml"
  if not (Hashtbl.mem tbl name) then
# 31 "cohttp/http_message.ml"
    raise (Header_not_found name);
# 32 "cohttp/http_message.ml"
  Hashtbl.remove tbl name;
# 33 "cohttp/http_message.ml"
  if Hashtbl.mem tbl name then hashtbl_remove_all tbl name
# 34 "cohttp/http_message.ml"

# 35 "cohttp/http_message.ml"
type contents =
# 36 "cohttp/http_message.ml"
    [ `Buffer of Buffer.t
# 37 "cohttp/http_message.ml"
    | `String of string
# 38 "cohttp/http_message.ml"
    | `Inchan of int64 * OS.Flow.t * unit Lwt.u
# 39 "cohttp/http_message.ml"
    ]
# 40 "cohttp/http_message.ml"

# 41 "cohttp/http_message.ml"
type message = {
# 42 "cohttp/http_message.ml"
  mutable m_contents : contents list;
# 43 "cohttp/http_message.ml"
  m_headers : (string, string) Hashtbl.t;
# 44 "cohttp/http_message.ml"
  m_version : version;
# 45 "cohttp/http_message.ml"
  m_cliaddr : string;
# 46 "cohttp/http_message.ml"
  m_cliport : int;
# 47 "cohttp/http_message.ml"
  m_srvaddr : string;
# 48 "cohttp/http_message.ml"
  m_srvport : int;
# 49 "cohttp/http_message.ml"
} 
# 50 "cohttp/http_message.ml"

# 51 "cohttp/http_message.ml"
let body msg = List.rev msg.m_contents
# 52 "cohttp/http_message.ml"
let body_size cl =
# 53 "cohttp/http_message.ml"
  let (+) = Int64.add in
# 54 "cohttp/http_message.ml"
    List.fold_left (fun a c -> match c with
# 55 "cohttp/http_message.ml"
		      | `String s -> a + (Int64.of_int (String.length s))
# 56 "cohttp/http_message.ml"
		      | `Buffer b -> a + (Int64.of_int (Buffer.length b))
# 57 "cohttp/http_message.ml"
		      | `Inchan (i, _, _) -> a + i) Int64.zero cl
# 58 "cohttp/http_message.ml"
let string_of_body cl =
# 59 "cohttp/http_message.ml"
  (* TODO: What if the body is larger than 1GB? *)
# 60 "cohttp/http_message.ml"
  let buf = String.create (Int64.to_int (body_size cl)) in
# 61 "cohttp/http_message.ml"
    (List.fold_left (fun pos c -> match c with
# 62 "cohttp/http_message.ml"
		       | `String s ->
# 63 "cohttp/http_message.ml"
			   lwt pos = pos in
# 64 "cohttp/http_message.ml"
                           let len = String.length s in
# 65 "cohttp/http_message.ml"
			   let () = String.blit s 0 buf pos len in
# 66 "cohttp/http_message.ml"
			     return (pos + len)
# 67 "cohttp/http_message.ml"
                       | `Buffer b ->
# 68 "cohttp/http_message.ml"
			   lwt pos = pos in
# 69 "cohttp/http_message.ml"
                           let len = Buffer.length b in
# 70 "cohttp/http_message.ml"
			   let str = Buffer.contents b in
# 71 "cohttp/http_message.ml"
			   let () = String.blit str 0 buf pos len in
# 72 "cohttp/http_message.ml"
			     return (pos + len)
# 73 "cohttp/http_message.ml"
	               | `Inchan (il, ic, finished) ->
# 74 "cohttp/http_message.ml"
			   lwt pos = pos in
# 75 "cohttp/http_message.ml"
                           let il = Int64.to_int il in
# 76 "cohttp/http_message.ml"
                             (OS.Flow.really_read ic buf pos il) >>
# 77 "cohttp/http_message.ml"
			       (Lwt.wakeup finished (); return (pos + il))
# 78 "cohttp/http_message.ml"
                    ) (return 0) cl) >>= (fun _ -> return buf)
# 79 "cohttp/http_message.ml"
let set_body msg contents = msg.m_contents <- [contents]
# 80 "cohttp/http_message.ml"
let add_body msg contents = msg.m_contents <- (contents :: msg.m_contents)
# 81 "cohttp/http_message.ml"
let add_header msg ~name ~value =
# 82 "cohttp/http_message.ml"
  let name = String.lowercase name in
# 83 "cohttp/http_message.ml"
  Hashtbl.add msg.m_headers name value
# 84 "cohttp/http_message.ml"
let add_headers msg =
# 85 "cohttp/http_message.ml"
  List.iter (fun (name, value) -> add_header msg ~name ~value)
# 86 "cohttp/http_message.ml"
let replace_header msg ~name ~value =
# 87 "cohttp/http_message.ml"
  let name = String.lowercase name in
# 88 "cohttp/http_message.ml"
  Hashtbl.replace msg.m_headers name value
# 89 "cohttp/http_message.ml"
let replace_headers msg =
# 90 "cohttp/http_message.ml"
  List.iter (fun (name, value) -> replace_header msg ~name ~value)
# 91 "cohttp/http_message.ml"
let remove_header msg ~name =
# 92 "cohttp/http_message.ml"
  let name = String.lowercase name in
# 93 "cohttp/http_message.ml"
  hashtbl_remove_all msg.m_headers name
# 94 "cohttp/http_message.ml"
let has_header msg ~name =
# 95 "cohttp/http_message.ml"
  Hashtbl.mem msg.m_headers name
# 96 "cohttp/http_message.ml"
let header msg ~name =
# 97 "cohttp/http_message.ml"
  let name = String.lowercase name in
# 98 "cohttp/http_message.ml"
  let compact = String.concat ", " in
# 99 "cohttp/http_message.ml"
    (* TODO: Just these old headers or all of HTTP 1.0? *)
# 100 "cohttp/http_message.ml"
  let no_compact = ["set-cookie"] in
# 101 "cohttp/http_message.ml"
    if has_header msg ~name then
# 102 "cohttp/http_message.ml"
      let hl = List.rev (Hashtbl.find_all msg.m_headers name) in
# 103 "cohttp/http_message.ml"
	if List.mem name no_compact then hl
# 104 "cohttp/http_message.ml"
	else [compact hl]
# 105 "cohttp/http_message.ml"
    else []
# 106 "cohttp/http_message.ml"
let headers msg =
# 107 "cohttp/http_message.ml"
  let hset = Hashtbl.create 11 in
# 108 "cohttp/http_message.ml"
  let () = Hashtbl.iter (fun name _ -> Hashtbl.replace hset name ()) msg.m_headers in
# 109 "cohttp/http_message.ml"
    Hashtbl.fold (fun name _ headers -> 
# 110 "cohttp/http_message.ml"
		    List.rev_append
# 111 "cohttp/http_message.ml"
		      (List.map (fun h -> (name, h)) (header msg ~name))
# 112 "cohttp/http_message.ml"
		      headers
# 113 "cohttp/http_message.ml"
		 ) hset []
# 114 "cohttp/http_message.ml"
    
# 115 "cohttp/http_message.ml"
let client_addr msg = msg.m_cliaddr
# 116 "cohttp/http_message.ml"
let server_addr msg = msg.m_srvaddr
# 117 "cohttp/http_message.ml"
let client_port msg = msg.m_cliport
# 118 "cohttp/http_message.ml"
let server_port msg = msg.m_srvport
# 119 "cohttp/http_message.ml"

# 120 "cohttp/http_message.ml"
let version msg = msg.m_version
# 121 "cohttp/http_message.ml"

# 122 "cohttp/http_message.ml"
let init ~body ~headers ~version ~clisockaddr ~srvsockaddr =
# 123 "cohttp/http_message.ml"
  let ((cliaddr, cliport), (srvaddr, srvport)) =
# 124 "cohttp/http_message.ml"
    (Http_misc.explode_sockaddr clisockaddr,
# 125 "cohttp/http_message.ml"
     Http_misc.explode_sockaddr srvsockaddr) in
# 126 "cohttp/http_message.ml"
  let msg = { m_contents = body;
# 127 "cohttp/http_message.ml"
	      m_headers = Hashtbl.create 11;
# 128 "cohttp/http_message.ml"
	      m_version = version;
# 129 "cohttp/http_message.ml"
	      m_cliaddr = cliaddr;
# 130 "cohttp/http_message.ml"
	      m_cliport = cliport;
# 131 "cohttp/http_message.ml"
	      m_srvaddr = srvaddr;
# 132 "cohttp/http_message.ml"
	      m_srvport = srvport;
# 133 "cohttp/http_message.ml"
	    } in
# 134 "cohttp/http_message.ml"
    add_headers msg headers;
# 135 "cohttp/http_message.ml"
    msg
# 136 "cohttp/http_message.ml"
      
# 137 "cohttp/http_message.ml"
let relay ic oc write m =
# 138 "cohttp/http_message.ml"
  let bufsize = 4096 in (* blksz *)
# 139 "cohttp/http_message.ml"
  let buffer = String.create bufsize in
# 140 "cohttp/http_message.ml"
  let rec aux m =
# 141 "cohttp/http_message.ml"
    m >>= function _ ->
# 142 "cohttp/http_message.ml"
      OS.Flow.read ic buffer 0 bufsize >>= function
# 143 "cohttp/http_message.ml"
      | 0   -> Lwt.return ()
# 144 "cohttp/http_message.ml"
      | len -> aux (write oc buffer 0 len)
# 145 "cohttp/http_message.ml"
  in aux m
# 146 "cohttp/http_message.ml"

# 147 "cohttp/http_message.ml"
let serialize msg outchan write_all write ~fstLineToString =
# 148 "cohttp/http_message.ml"
  let body = body msg in
# 149 "cohttp/http_message.ml"
  let bodylen = body_size body in
# 150 "cohttp/http_message.ml"
  write_all outchan (fstLineToString ^ crlf) >>
# 151 "cohttp/http_message.ml"
  List.fold_left
# 152 "cohttp/http_message.ml"
    (fun m (h,v) -> m >> write_all outchan (h ^ ": " ^ v ^ crlf))
# 153 "cohttp/http_message.ml"
	(Lwt.return ())
# 154 "cohttp/http_message.ml"
	(headers msg) >>
# 155 "cohttp/http_message.ml"
  (if bodylen != Int64.zero then
# 156 "cohttp/http_message.ml"
	write_all outchan (sprintf "Content-Length: %Ld\r\n\r\n" bodylen)
# 157 "cohttp/http_message.ml"
  else return ()) >>
# 158 "cohttp/http_message.ml"
  List.fold_left
# 159 "cohttp/http_message.ml"
    (fun m c -> match c with
# 160 "cohttp/http_message.ml"
       | `String s -> m >> (write_all outchan s)
# 161 "cohttp/http_message.ml"
	   | `Buffer b -> m >> (write_all outchan (Buffer.contents b))
# 162 "cohttp/http_message.ml"
	   | `Inchan (_, ic, finished) -> relay ic outchan write m >> (Lwt.wakeup finished (); Lwt.return ()))
# 163 "cohttp/http_message.ml"
	(Lwt.return ())
# 164 "cohttp/http_message.ml"
	body
# 165 "cohttp/http_message.ml"

# 166 "cohttp/http_message.ml"
let serialize_to_output_channel msg outchan ~fstLineToString =
# 167 "cohttp/http_message.ml"
  serialize msg outchan OS.Flow.write_all OS.Flow.really_write ~fstLineToString
# 168 "cohttp/http_message.ml"

# 169 "cohttp/http_message.ml"
let serialize_to_stream msg ~fstLineToString =
# 170 "cohttp/http_message.ml"
  let stream, push = Lwt_stream.create () in
# 171 "cohttp/http_message.ml"
  Lwt.ignore_result
# 172 "cohttp/http_message.ml"
    (serialize
# 173 "cohttp/http_message.ml"
       msg
# 174 "cohttp/http_message.ml"
       ()
# 175 "cohttp/http_message.ml"
       (fun () s -> push (Some s); Lwt.return ())
# 176 "cohttp/http_message.ml"
       (fun () buf off len -> push (Some (String.sub buf off len)); Lwt.return ())
# 177 "cohttp/http_message.ml"
       ~fstLineToString >> (push None; Lwt.return ()));
# 178 "cohttp/http_message.ml"
  stream
# 179 "cohttp/http_message.ml"
end
module Http_response : sig
# 1 "cohttp/http_response.mli"
open Mlnet.Types
# 2 "cohttp/http_response.mli"

# 3 "cohttp/http_response.mli"
type response
# 4 "cohttp/http_response.mli"
val init :
# 5 "cohttp/http_response.mli"
  ?body:Http_message.contents list ->
# 6 "cohttp/http_response.mli"
  ?headers:(string * string) list ->
# 7 "cohttp/http_response.mli"
  ?version:Http_types.version ->
# 8 "cohttp/http_response.mli"
  ?status:Http_types.status_code ->
# 9 "cohttp/http_response.mli"
  ?reason:string ->
# 10 "cohttp/http_response.mli"
  ?clisockaddr:sockaddr ->
# 11 "cohttp/http_response.mli"
  ?srvsockaddr:sockaddr -> unit -> response
# 12 "cohttp/http_response.mli"
val version_string : response -> string
# 13 "cohttp/http_response.mli"
val code : response -> int
# 14 "cohttp/http_response.mli"
val set_code : response -> int -> unit
# 15 "cohttp/http_response.mli"
val status : response -> Http_types.status
# 16 "cohttp/http_response.mli"
val set_status : response -> Http_types.status -> unit
# 17 "cohttp/http_response.mli"
val reason : response -> string
# 18 "cohttp/http_response.mli"
val set_reason : response -> string -> unit
# 19 "cohttp/http_response.mli"
val status_line : response -> string
# 20 "cohttp/http_response.mli"
val is_informational : response -> bool
# 21 "cohttp/http_response.mli"
val is_success : response -> bool
# 22 "cohttp/http_response.mli"
val is_redirection : response -> bool
# 23 "cohttp/http_response.mli"
val is_client_error : response -> bool
# 24 "cohttp/http_response.mli"
val is_server_error : response -> bool
# 25 "cohttp/http_response.mli"
val is_error : response -> bool
# 26 "cohttp/http_response.mli"
val add_basic_headers : response -> unit
# 27 "cohttp/http_response.mli"
val content_type : response -> string option
# 28 "cohttp/http_response.mli"
val set_content_type : response -> value:string -> unit
# 29 "cohttp/http_response.mli"
val content_encoding : response -> string option
# 30 "cohttp/http_response.mli"
val set_content_encoding : response -> value:string -> unit
# 31 "cohttp/http_response.mli"
val date : response -> string option
# 32 "cohttp/http_response.mli"
val set_date : response -> value:string -> unit
# 33 "cohttp/http_response.mli"
val expires : response -> string option
# 34 "cohttp/http_response.mli"
val set_expires : response -> value:string -> unit
# 35 "cohttp/http_response.mli"
val server : response -> string option
# 36 "cohttp/http_response.mli"
val set_server : response -> value:string -> unit
# 37 "cohttp/http_response.mli"
val serialize :
# 38 "cohttp/http_response.mli"
  response ->
# 39 "cohttp/http_response.mli"
  'a -> ('a -> string -> unit Lwt.t) -> ('a -> string -> int -> int -> unit Lwt.t) ->
# 40 "cohttp/http_response.mli"
  unit Lwt.t
# 41 "cohttp/http_response.mli"
val serialize_to_output_channel : response -> OS.Flow.t -> unit Lwt.t
# 42 "cohttp/http_response.mli"
val serialize_to_stream : response -> string Lwt_stream.t
# 43 "cohttp/http_response.mli"
end = struct
# 1 "cohttp/http_response.ml"

# 2 "cohttp/http_response.ml"
(*
# 3 "cohttp/http_response.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_response.ml"

# 5 "cohttp/http_response.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 6 "cohttp/http_response.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 7 "cohttp/http_response.ml"
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
# 8 "cohttp/http_response.ml"

# 9 "cohttp/http_response.ml"
  This program is free software; you can redistribute it and/or modify
# 10 "cohttp/http_response.ml"
  it under the terms of the GNU Library General Public License as
# 11 "cohttp/http_response.ml"
  published by the Free Software Foundation, version 2.
# 12 "cohttp/http_response.ml"

# 13 "cohttp/http_response.ml"
  This program is distributed in the hope that it will be useful,
# 14 "cohttp/http_response.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 15 "cohttp/http_response.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 16 "cohttp/http_response.ml"
  GNU Library General Public License for more details.
# 17 "cohttp/http_response.ml"

# 18 "cohttp/http_response.ml"
  You should have received a copy of the GNU Library General Public
# 19 "cohttp/http_response.ml"
  License along with this program; if not, write to the Free Software
# 20 "cohttp/http_response.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 21 "cohttp/http_response.ml"
  USA
# 22 "cohttp/http_response.ml"
*)
# 23 "cohttp/http_response.ml"

# 24 "cohttp/http_response.ml"
open Http_types
# 25 "cohttp/http_response.ml"
open Http_constants
# 26 "cohttp/http_response.ml"
open Http_common
# 27 "cohttp/http_response.ml"
open Printf
# 28 "cohttp/http_response.ml"
open Lwt
# 29 "cohttp/http_response.ml"
open Mlnet.Types
# 30 "cohttp/http_response.ml"

# 31 "cohttp/http_response.ml"
let anyize = function
# 32 "cohttp/http_response.ml"
  | Some addr -> addr
# 33 "cohttp/http_response.ml"
  | None ->
# 34 "cohttp/http_response.ml"
    let addr = match Mlnet.Types.ipv4_addr_of_string "0.0.0.0" with
# 35 "cohttp/http_response.ml"
      | Some x -> x
# 36 "cohttp/http_response.ml"
      | None   -> failwith "anyize" in
# 37 "cohttp/http_response.ml"
    TCP (addr, -1)
# 38 "cohttp/http_response.ml"

# 39 "cohttp/http_response.ml"
type response = {
# 40 "cohttp/http_response.ml"
  r_msg: Http_message.message;
# 41 "cohttp/http_response.ml"
  mutable r_code: int;
# 42 "cohttp/http_response.ml"
  mutable r_reason: string option;
# 43 "cohttp/http_response.ml"
}
# 44 "cohttp/http_response.ml"

# 45 "cohttp/http_response.ml"
let add_basic_headers r =
# 46 "cohttp/http_response.ml"
  Http_message.add_header r.r_msg ~name:"Date" ~value:(Http_misc.date_822 ());
# 47 "cohttp/http_response.ml"
  Http_message.add_header r.r_msg ~name:"Server" ~value:server_string
# 48 "cohttp/http_response.ml"

# 49 "cohttp/http_response.ml"
let init
# 50 "cohttp/http_response.ml"
    ?(body = [`String ""]) ?(headers = []) ?(version = default_version)
# 51 "cohttp/http_response.ml"
    ?(status=`Code 200) ?reason ?clisockaddr ?srvsockaddr ()
# 52 "cohttp/http_response.ml"
    =
# 53 "cohttp/http_response.ml"
  let (clisockaddr, srvsockaddr) = (anyize clisockaddr, anyize srvsockaddr) in
# 54 "cohttp/http_response.ml"
  let r = { r_msg = Http_message.init ~body ~headers ~version ~clisockaddr ~srvsockaddr;
# 55 "cohttp/http_response.ml"
	    r_code = begin match status with
# 56 "cohttp/http_response.ml"
	      | `Code c -> c
# 57 "cohttp/http_response.ml"
	      | #status as s -> code_of_status s
# 58 "cohttp/http_response.ml"
	    end;
# 59 "cohttp/http_response.ml"
	    r_reason = reason } in
# 60 "cohttp/http_response.ml"
  let () = add_basic_headers r in r
# 61 "cohttp/http_response.ml"

# 62 "cohttp/http_response.ml"
let version_string r = string_of_version (Http_message.version r.r_msg)
# 63 "cohttp/http_response.ml"

# 64 "cohttp/http_response.ml"
let code r = r.r_code
# 65 "cohttp/http_response.ml"
let set_code r c = 
# 66 "cohttp/http_response.ml"
   ignore (status_of_code c);  (* sanity check on c *)
# 67 "cohttp/http_response.ml"
   r.r_code <- c
# 68 "cohttp/http_response.ml"
let status r = status_of_code (code r)
# 69 "cohttp/http_response.ml"
let set_status r (s: Http_types.status) = r.r_code <- code_of_status s
# 70 "cohttp/http_response.ml"
let reason r =
# 71 "cohttp/http_response.ml"
   match r.r_reason with
# 72 "cohttp/http_response.ml"
      | None -> Http_misc.reason_phrase_of_code r.r_code
# 73 "cohttp/http_response.ml"
      | Some r -> r
# 74 "cohttp/http_response.ml"
let set_reason r rs = r.r_reason <- Some rs
# 75 "cohttp/http_response.ml"
let status_line r =
# 76 "cohttp/http_response.ml"
      String.concat " "
# 77 "cohttp/http_response.ml"
        [version_string r; string_of_int (code r); reason r ]
# 78 "cohttp/http_response.ml"

# 79 "cohttp/http_response.ml"
let is_informational r = Http_common.is_informational r.r_code
# 80 "cohttp/http_response.ml"
let is_success r = Http_common.is_success r.r_code
# 81 "cohttp/http_response.ml"
let is_redirection r = Http_common.is_redirection r.r_code
# 82 "cohttp/http_response.ml"
let is_client_error r = Http_common.is_client_error r.r_code
# 83 "cohttp/http_response.ml"
let is_server_error r = Http_common.is_server_error r.r_code
# 84 "cohttp/http_response.ml"
let is_error r = Http_common.is_error r.r_code
# 85 "cohttp/http_response.ml"

# 86 "cohttp/http_response.ml"
let gh name r =
# 87 "cohttp/http_response.ml"
  match Http_message.header r.r_msg ~name with [] -> None | x :: _ -> Some x
# 88 "cohttp/http_response.ml"
let rh name r = Http_message.replace_header r.r_msg ~name
# 89 "cohttp/http_response.ml"

# 90 "cohttp/http_response.ml"
let content_type = gh "Content-Type"
# 91 "cohttp/http_response.ml"
let set_content_type = rh "Content-Type"
# 92 "cohttp/http_response.ml"
let content_encoding = gh "Content-Encoding"
# 93 "cohttp/http_response.ml"
let set_content_encoding = rh "Content-Encoding"
# 94 "cohttp/http_response.ml"
let date = gh "Date"
# 95 "cohttp/http_response.ml"
let set_date = rh "Date"
# 96 "cohttp/http_response.ml"
let expires = gh "Expires"
# 97 "cohttp/http_response.ml"
let set_expires = rh "Expires"
# 98 "cohttp/http_response.ml"
let server = gh "Server"
# 99 "cohttp/http_response.ml"
let set_server = rh "Server"
# 100 "cohttp/http_response.ml"

# 101 "cohttp/http_response.ml"
let fstLineToString r =
# 102 "cohttp/http_response.ml"
  sprintf "%s %d %s" (version_string r) (code r) (reason r)
# 103 "cohttp/http_response.ml"

# 104 "cohttp/http_response.ml"
let serialize r outchan write write_from_exactly = 
# 105 "cohttp/http_response.ml"
  let fstLineToString = fstLineToString r in
# 106 "cohttp/http_response.ml"
  Http_message.serialize r.r_msg outchan write write_from_exactly ~fstLineToString
# 107 "cohttp/http_response.ml"

# 108 "cohttp/http_response.ml"
let serialize_to_output_channel r outchan =
# 109 "cohttp/http_response.ml"
  let fstLineToString = fstLineToString r in
# 110 "cohttp/http_response.ml"
  Http_message.serialize_to_output_channel r.r_msg outchan ~fstLineToString
# 111 "cohttp/http_response.ml"

# 112 "cohttp/http_response.ml"
let serialize_to_stream r =
# 113 "cohttp/http_response.ml"
  let fstLineToString = fstLineToString r in
# 114 "cohttp/http_response.ml"
  Http_message.serialize_to_stream r.r_msg ~fstLineToString
# 115 "cohttp/http_response.ml"
end
module Http_request : sig
# 1 "cohttp/http_request.mli"
open Mlnet.Types
# 2 "cohttp/http_request.mli"

# 3 "cohttp/http_request.mli"
type request
# 4 "cohttp/http_request.mli"
val init_request :
# 5 "cohttp/http_request.mli"
  clisockaddr:sockaddr ->
# 6 "cohttp/http_request.mli"
  srvsockaddr:sockaddr -> unit Lwt.u -> OS.Flow.t -> request Lwt.t
# 7 "cohttp/http_request.mli"
val meth : request -> Http_types.meth
# 8 "cohttp/http_request.mli"
val uri : request -> string
# 9 "cohttp/http_request.mli"
val path : request -> string
# 10 "cohttp/http_request.mli"
val body : request -> Http_message.contents list
# 11 "cohttp/http_request.mli"
val param :
# 12 "cohttp/http_request.mli"
  ?meth:[< `GET | `POST ] -> ?default:string -> request -> string -> string
# 13 "cohttp/http_request.mli"
val param_all : ?meth:Http_types.meth -> request -> string -> string list
# 14 "cohttp/http_request.mli"
val params : request -> (string, string) Hashtbl.t
# 15 "cohttp/http_request.mli"
val params_get : request -> (string * string) list
# 16 "cohttp/http_request.mli"
val params_post : request -> (string * string) list
# 17 "cohttp/http_request.mli"
val authorization : request -> [> `Basic of string * string ] option
# 18 "cohttp/http_request.mli"
val header : request -> name:string -> string list
# 19 "cohttp/http_request.mli"
val client_addr : request -> string
# 20 "cohttp/http_request.mli"
end = struct
# 1 "cohttp/http_request.ml"
(*
# 2 "cohttp/http_request.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_request.ml"

# 4 "cohttp/http_request.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_request.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 6 "cohttp/http_request.ml"
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
# 7 "cohttp/http_request.ml"

# 8 "cohttp/http_request.ml"
  This program is free software; you can redistribute it and/or modify
# 9 "cohttp/http_request.ml"
  it under the terms of the GNU Library General Public License as
# 10 "cohttp/http_request.ml"
  published by the Free Software Foundation, version 2.
# 11 "cohttp/http_request.ml"

# 12 "cohttp/http_request.ml"
  This program is distributed in the hope that it will be useful,
# 13 "cohttp/http_request.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 14 "cohttp/http_request.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 15 "cohttp/http_request.ml"
  GNU Library General Public License for more details.
# 16 "cohttp/http_request.ml"

# 17 "cohttp/http_request.ml"
  You should have received a copy of the GNU Library General Public
# 18 "cohttp/http_request.ml"
  License along with this program; if not, write to the Free Software
# 19 "cohttp/http_request.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 20 "cohttp/http_request.ml"
  USA
# 21 "cohttp/http_request.ml"
*)
# 22 "cohttp/http_request.ml"

# 23 "cohttp/http_request.ml"
open Printf
# 24 "cohttp/http_request.ml"
open Lwt
# 25 "cohttp/http_request.ml"

# 26 "cohttp/http_request.ml"
open Http_common
# 27 "cohttp/http_request.ml"
open Http_types
# 28 "cohttp/http_request.ml"

# 29 "cohttp/http_request.ml"
let debug_dump_request path params =
# 30 "cohttp/http_request.ml"
  debug_print ("request path = " ^ path);
# 31 "cohttp/http_request.ml"
  debug_print (
# 32 "cohttp/http_request.ml"
    sprintf"request params = %s"
# 33 "cohttp/http_request.ml"
      (String.concat ";"
# 34 "cohttp/http_request.ml"
        (List.map (fun (h,v) -> String.concat "=" [h;v]) params)))
# 35 "cohttp/http_request.ml"

# 36 "cohttp/http_request.ml"
let auth_sep_RE = Str.regexp_string ":"
# 37 "cohttp/http_request.ml"
let basic_auth_RE = Str.regexp "^Basic +"
# 38 "cohttp/http_request.ml"

# 39 "cohttp/http_request.ml"
type request = {
# 40 "cohttp/http_request.ml"
  r_msg: Http_message.message;
# 41 "cohttp/http_request.ml"
  r_params: (string, string) Hashtbl.t;
# 42 "cohttp/http_request.ml"
  r_get_params: (string * string) list;
# 43 "cohttp/http_request.ml"
  r_post_params: (string * string) list;
# 44 "cohttp/http_request.ml"
  r_meth: meth;
# 45 "cohttp/http_request.ml"
  r_uri: string;
# 46 "cohttp/http_request.ml"
  r_version: version;
# 47 "cohttp/http_request.ml"
  r_path: string;
# 48 "cohttp/http_request.ml"
}
# 49 "cohttp/http_request.ml"
 
# 50 "cohttp/http_request.ml"
let init_request ~clisockaddr ~srvsockaddr finished ic =
# 51 "cohttp/http_request.ml"
  debug_print "init_request";
# 52 "cohttp/http_request.ml"
  lwt (meth, uri, version) = Http_parser.parse_request_fst_line ic in
# 53 "cohttp/http_request.ml"
  let uri_str = Http_url.to_string uri in
# 54 "cohttp/http_request.ml"
  debug_print (Printf.sprintf ">>> URL=%s" uri_str);
# 55 "cohttp/http_request.ml"
  let path = Http_parser.parse_path uri in
# 56 "cohttp/http_request.ml"
  let query_get_params = Http_parser.parse_query_get_params uri in
# 57 "cohttp/http_request.ml"
  lwt headers = Http_parser.parse_headers ic in
# 58 "cohttp/http_request.ml"
  let headers = List.map (fun (h,v) -> (String.lowercase h, v)) headers in
# 59 "cohttp/http_request.ml"
  lwt body = (if meth = `POST then begin
# 60 "cohttp/http_request.ml"
		let limit = try Some 
# 61 "cohttp/http_request.ml"
                  (Int64.of_string (List.assoc "content-length" headers))
# 62 "cohttp/http_request.ml"
		with Not_found -> None in
# 63 "cohttp/http_request.ml"
		  match limit with 
# 64 "cohttp/http_request.ml"
		    |None -> OS.Flow.read_all ic >|= (fun s -> Lwt.wakeup finished (); [`String s])
# 65 "cohttp/http_request.ml"
		    |Some count -> return [`Inchan (count, ic, finished)]
# 66 "cohttp/http_request.ml"
              end
# 67 "cohttp/http_request.ml"
              else  (* TODO empty body for methods other than POST, is ok? *)
# 68 "cohttp/http_request.ml"
		(Lwt.wakeup finished (); return [`String ""])) in
# 69 "cohttp/http_request.ml"
  lwt query_post_params, body =
# 70 "cohttp/http_request.ml"
    match meth with
# 71 "cohttp/http_request.ml"
      | `POST -> begin
# 72 "cohttp/http_request.ml"
          try
# 73 "cohttp/http_request.ml"
	    let ct = List.assoc "content-type" headers in
# 74 "cohttp/http_request.ml"
	      if ct = "application/x-www-form-urlencoded" then
# 75 "cohttp/http_request.ml"
		(Http_message.string_of_body body) >|= (fun s -> Http_parser.split_query_params s, [`String s])
# 76 "cohttp/http_request.ml"
	      else return ([], body)
# 77 "cohttp/http_request.ml"
	  with Not_found -> return ([], body)
# 78 "cohttp/http_request.ml"
	end
# 79 "cohttp/http_request.ml"
      | _ -> return ([], body)
# 80 "cohttp/http_request.ml"
  in
# 81 "cohttp/http_request.ml"
  let params = query_post_params @ query_get_params in (* prefers POST params *)
# 82 "cohttp/http_request.ml"
  let _ = debug_dump_request path params in
# 83 "cohttp/http_request.ml"
  let msg = Http_message.init ~body ~headers ~version ~clisockaddr ~srvsockaddr in
# 84 "cohttp/http_request.ml"
  let params_tbl =
# 85 "cohttp/http_request.ml"
    let tbl = Hashtbl.create (List.length params) in
# 86 "cohttp/http_request.ml"
      List.iter (fun (n,v) -> Hashtbl.add tbl n v) params;
# 87 "cohttp/http_request.ml"
      tbl in
# 88 "cohttp/http_request.ml"
    return { r_msg=msg; r_params=params_tbl; r_get_params = query_get_params; 
# 89 "cohttp/http_request.ml"
             r_post_params = query_post_params; r_uri=uri_str; r_meth=meth; 
# 90 "cohttp/http_request.ml"
             r_version=version; r_path=path }
# 91 "cohttp/http_request.ml"

# 92 "cohttp/http_request.ml"
let meth r = r.r_meth
# 93 "cohttp/http_request.ml"
let uri r = r.r_uri
# 94 "cohttp/http_request.ml"
let path r = r.r_path
# 95 "cohttp/http_request.ml"
let body r = Http_message.body r.r_msg
# 96 "cohttp/http_request.ml"
let header r ~name = Http_message.header r.r_msg ~name
# 97 "cohttp/http_request.ml"
let client_addr r = Http_message.client_addr r.r_msg
# 98 "cohttp/http_request.ml"

# 99 "cohttp/http_request.ml"
let param ?meth ?default r name =
# 100 "cohttp/http_request.ml"
  try
# 101 "cohttp/http_request.ml"
    (match meth with
# 102 "cohttp/http_request.ml"
     | None -> Hashtbl.find r.r_params name
# 103 "cohttp/http_request.ml"
     | Some `GET -> List.assoc name r.r_get_params
# 104 "cohttp/http_request.ml"
     | Some `POST -> List.assoc name r.r_post_params)
# 105 "cohttp/http_request.ml"
   with Not_found ->
# 106 "cohttp/http_request.ml"
        (match default with
# 107 "cohttp/http_request.ml"
        | None -> raise (Param_not_found name)
# 108 "cohttp/http_request.ml"
        | Some value -> value)
# 109 "cohttp/http_request.ml"

# 110 "cohttp/http_request.ml"
let param_all ?meth r name =
# 111 "cohttp/http_request.ml"
  (match (meth: meth option) with
# 112 "cohttp/http_request.ml"
   | None -> List.rev (Hashtbl.find_all r.r_params name)
# 113 "cohttp/http_request.ml"
   | Some `DELETE
# 114 "cohttp/http_request.ml"
   | Some `HEAD
# 115 "cohttp/http_request.ml"
   | Some `GET -> Http_misc.list_assoc_all name r.r_get_params
# 116 "cohttp/http_request.ml"
   | Some `POST -> Http_misc.list_assoc_all name r.r_post_params)
# 117 "cohttp/http_request.ml"

# 118 "cohttp/http_request.ml"
let params r = r.r_params
# 119 "cohttp/http_request.ml"
let params_get r = r.r_get_params
# 120 "cohttp/http_request.ml"
let params_post r = r.r_post_params
# 121 "cohttp/http_request.ml"

# 122 "cohttp/http_request.ml"
let authorization r = 
# 123 "cohttp/http_request.ml"
  match Http_message.header r.r_msg ~name:"authorization" with
# 124 "cohttp/http_request.ml"
    | [] -> None
# 125 "cohttp/http_request.ml"
    | h :: _ -> 
# 126 "cohttp/http_request.ml"
	let credentials = Base64.decode (Str.replace_first basic_auth_RE "" h) in
# 127 "cohttp/http_request.ml"
	  debug_print ("HTTP Basic auth credentials: " ^ credentials);
# 128 "cohttp/http_request.ml"
	  (match Str.split auth_sep_RE credentials with
# 129 "cohttp/http_request.ml"
	     | [username; password] -> Some (`Basic (username, password))
# 130 "cohttp/http_request.ml"
	     | l -> None)
# 131 "cohttp/http_request.ml"

# 132 "cohttp/http_request.ml"
end
module Http_cookie : sig
# 1 "cohttp/http_cookie.mli"
type time =
# 2 "cohttp/http_cookie.mli"
    [ `Day of int | `Hour of int | `Minute of int | `Second of int ] list
# 3 "cohttp/http_cookie.mli"
type expiration = [ `Age of time | `Discard | `Session | `Until of float ]
# 4 "cohttp/http_cookie.mli"
type cookie
# 5 "cohttp/http_cookie.mli"

# 6 "cohttp/http_cookie.mli"
val make :
# 7 "cohttp/http_cookie.mli"
  ?expiry:expiration ->
# 8 "cohttp/http_cookie.mli"
  ?path:string ->
# 9 "cohttp/http_cookie.mli"
  ?domain:string -> ?secure:bool -> string -> string -> string * cookie
# 10 "cohttp/http_cookie.mli"
val serialize :
# 11 "cohttp/http_cookie.mli"
  ?version:[ `HTTP_1_0 | `HTTP_1_1 ] ->
# 12 "cohttp/http_cookie.mli"
  string * cookie -> string * string
# 13 "cohttp/http_cookie.mli"
val extract : Http_request.request -> (string * string) list
# 14 "cohttp/http_cookie.mli"
end = struct
# 1 "cohttp/http_cookie.ml"

# 2 "cohttp/http_cookie.ml"
(*
# 3 "cohttp/http_cookie.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 4 "cohttp/http_cookie.ml"

# 5 "cohttp/http_cookie.ml"
  Copyright (C) <2009> David Sheets <sheets@alum.mit.edu>
# 6 "cohttp/http_cookie.ml"

# 7 "cohttp/http_cookie.ml"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_cookie.ml"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_cookie.ml"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_cookie.ml"

# 11 "cohttp/http_cookie.ml"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_cookie.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_cookie.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_cookie.ml"
  GNU Library General Public License for more details.
# 15 "cohttp/http_cookie.ml"

# 16 "cohttp/http_cookie.ml"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_cookie.ml"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_cookie.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_cookie.ml"
  USA
# 20 "cohttp/http_cookie.ml"
*)
# 21 "cohttp/http_cookie.ml"

# 22 "cohttp/http_cookie.ml"
type time = [ `Day of int | `Hour of int | `Minute of int | `Second of int ] list
# 23 "cohttp/http_cookie.ml"
type expiration = [ `Discard | `Session | `Age of time | `Until of float ]
# 24 "cohttp/http_cookie.ml"

# 25 "cohttp/http_cookie.ml"
type cookie = { value : string;
# 26 "cohttp/http_cookie.ml"
		expiration : expiration;
# 27 "cohttp/http_cookie.ml"
		domain : string option;
# 28 "cohttp/http_cookie.ml"
		path : string option;
# 29 "cohttp/http_cookie.ml"
		secure : bool }
# 30 "cohttp/http_cookie.ml"

# 31 "cohttp/http_cookie.ml"
(* Does not check the contents of name or value for ';', ',', '\s', or name[0]='$' *)
# 32 "cohttp/http_cookie.ml"
let make ?(expiry=`Session) ?path ?domain ?(secure=false) n v =
# 33 "cohttp/http_cookie.ml"
  (n, { value = v;
# 34 "cohttp/http_cookie.ml"
	expiration = expiry; domain = domain;
# 35 "cohttp/http_cookie.ml"
	path = path; secure = secure })
# 36 "cohttp/http_cookie.ml"
    
# 37 "cohttp/http_cookie.ml"
let duration tml =
# 38 "cohttp/http_cookie.ml"
  let tval = function
# 39 "cohttp/http_cookie.ml"
    | `Day d -> 86400*d
# 40 "cohttp/http_cookie.ml"
    | `Hour h -> 3600*h
# 41 "cohttp/http_cookie.ml"
    | `Minute m -> 60*m
# 42 "cohttp/http_cookie.ml"
    | `Second s -> s
# 43 "cohttp/http_cookie.ml"
  in List.fold_left (fun a t -> a + (tval t)) 0 tml
# 44 "cohttp/http_cookie.ml"

# 45 "cohttp/http_cookie.ml"
let serialize_1_1 (n, c) =
# 46 "cohttp/http_cookie.ml"
  let attrs = ["Version=1"] in
# 47 "cohttp/http_cookie.ml"
  let attrs = if c.secure then ("Secure" :: attrs) else attrs in
# 48 "cohttp/http_cookie.ml"
  let attrs = match c.path with None -> attrs
# 49 "cohttp/http_cookie.ml"
    | Some p -> ("Path=" ^ p) :: attrs in
# 50 "cohttp/http_cookie.ml"
  let attrs = match c.expiration with
# 51 "cohttp/http_cookie.ml"
    | `Discard -> "Max-Age=0" :: attrs
# 52 "cohttp/http_cookie.ml"
    | `Session -> "Discard" :: attrs
# 53 "cohttp/http_cookie.ml"
    | `Until stamp ->
# 54 "cohttp/http_cookie.ml"
	let offset = int_of_float (stamp -. (OS.Clock.time ())) in
# 55 "cohttp/http_cookie.ml"
	  ("Max-Age=" ^ (string_of_int (min 0 offset))) :: attrs
# 56 "cohttp/http_cookie.ml"
    | `Age tml -> ("Max-Age=" ^ (string_of_int (duration tml))) :: attrs in
# 57 "cohttp/http_cookie.ml"
  let attrs = match c.domain with None -> attrs
# 58 "cohttp/http_cookie.ml"
    | Some d -> ("Domain=" ^ d) :: attrs in
# 59 "cohttp/http_cookie.ml"
    ("Set-Cookie2", String.concat "; " attrs)
# 60 "cohttp/http_cookie.ml"
  
# 61 "cohttp/http_cookie.ml"
let serialize_1_0 (n, c) =
# 62 "cohttp/http_cookie.ml"
  let fmt_time a = Http_misc.rfc822_of_float a in
# 63 "cohttp/http_cookie.ml"
  let attrs = if c.secure then ["secure"] else [] in
# 64 "cohttp/http_cookie.ml"
  let attrs = match c.path with None -> attrs
# 65 "cohttp/http_cookie.ml"
    | Some p -> ("path=" ^ p) :: attrs in
# 66 "cohttp/http_cookie.ml"
  let attrs = match c.domain with None -> attrs
# 67 "cohttp/http_cookie.ml"
    | Some d -> ("domain=" ^ d) :: attrs in
# 68 "cohttp/http_cookie.ml"
  let attrs = match c.expiration with
# 69 "cohttp/http_cookie.ml"
    | `Discard -> ("expires=" ^ (fmt_time 0.)) :: attrs
# 70 "cohttp/http_cookie.ml"
    | `Session -> attrs
# 71 "cohttp/http_cookie.ml"
    | `Until stamp -> ("expires=" ^ (fmt_time stamp)) :: attrs
# 72 "cohttp/http_cookie.ml"
    | `Age tml ->
# 73 "cohttp/http_cookie.ml"
	let age = float (duration tml) in
# 74 "cohttp/http_cookie.ml"
	  ("expires=" ^ (fmt_time ((OS.Clock.time ()) +. age))) :: attrs in
# 75 "cohttp/http_cookie.ml"
  let attrs = (n ^ (match c.value with "" -> ""
# 76 "cohttp/http_cookie.ml"
		      | v -> "=" ^ v)) :: attrs in
# 77 "cohttp/http_cookie.ml"
    ("Set-Cookie", String.concat "; " attrs)
# 78 "cohttp/http_cookie.ml"

# 79 "cohttp/http_cookie.ml"
let serialize ?(version=`HTTP_1_0) cp =
# 80 "cohttp/http_cookie.ml"
  match version with
# 81 "cohttp/http_cookie.ml"
    | `HTTP_1_0 -> serialize_1_0 cp
# 82 "cohttp/http_cookie.ml"
    | `HTTP_1_1 -> serialize_1_1 cp
# 83 "cohttp/http_cookie.ml"

# 84 "cohttp/http_cookie.ml"
let extract req =
# 85 "cohttp/http_cookie.ml"
  List.fold_left
# 86 "cohttp/http_cookie.ml"
    (fun acc header ->
# 87 "cohttp/http_cookie.ml"
       let comps = Str.(split (regexp "(?:;|,)\\s") header) in
# 88 "cohttp/http_cookie.ml"
       let cookies = List.filter (fun s -> s.[0] != '$') comps in
# 89 "cohttp/http_cookie.ml"
       let split_pair nvp =
# 90 "cohttp/http_cookie.ml"
         match Str.(split (regexp_string "=")) nvp with
# 91 "cohttp/http_cookie.ml"
         | [] -> ("","")
# 92 "cohttp/http_cookie.ml"
         | n :: [] -> (n, "")
# 93 "cohttp/http_cookie.ml"
         | n :: v :: _ -> (n, v)
# 94 "cohttp/http_cookie.ml"
       in (List.map split_pair cookies) @ acc
# 95 "cohttp/http_cookie.ml"
    ) [] (Http_request.header req "Cookie")
# 96 "cohttp/http_cookie.ml"
end
module Http_daemon : sig
# 1 "cohttp/http_daemon.mli"
open Mlnet.Types
# 2 "cohttp/http_daemon.mli"

# 3 "cohttp/http_daemon.mli"
type conn_id
# 4 "cohttp/http_daemon.mli"
val string_of_conn_id : conn_id -> string
# 5 "cohttp/http_daemon.mli"

# 6 "cohttp/http_daemon.mli"
type daemon_spec = {
# 7 "cohttp/http_daemon.mli"
  address : string;
# 8 "cohttp/http_daemon.mli"
  auth : Http_types.auth_info;
# 9 "cohttp/http_daemon.mli"
  callback : conn_id -> Http_request.request -> string Lwt_stream.t Lwt.t;
# 10 "cohttp/http_daemon.mli"
  conn_closed : conn_id -> unit;
# 11 "cohttp/http_daemon.mli"
  port : int;
# 12 "cohttp/http_daemon.mli"
  exn_handler : exn -> unit Lwt.t;
# 13 "cohttp/http_daemon.mli"
  timeout : float option;
# 14 "cohttp/http_daemon.mli"
}
# 15 "cohttp/http_daemon.mli"
val respond :
# 16 "cohttp/http_daemon.mli"
  ?body:string ->
# 17 "cohttp/http_daemon.mli"
  ?headers:(string * string) list ->
# 18 "cohttp/http_daemon.mli"
  ?version:Http_types.version ->
# 19 "cohttp/http_daemon.mli"
  ?status:Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
# 20 "cohttp/http_daemon.mli"
val respond_control :
# 21 "cohttp/http_daemon.mli"
  string ->
# 22 "cohttp/http_daemon.mli"
  ?is_valid_status:(int -> bool) ->
# 23 "cohttp/http_daemon.mli"
  ?headers:(string * string) list ->
# 24 "cohttp/http_daemon.mli"
  ?body:string ->
# 25 "cohttp/http_daemon.mli"
  ?version:Http_types.version ->
# 26 "cohttp/http_daemon.mli"
  Http_types.status_code -> string Lwt_stream.t Lwt.t
# 27 "cohttp/http_daemon.mli"
val respond_redirect :
# 28 "cohttp/http_daemon.mli"
  location:string ->
# 29 "cohttp/http_daemon.mli"
  ?body:string ->
# 30 "cohttp/http_daemon.mli"
  ?version:Http_types.version ->
# 31 "cohttp/http_daemon.mli"
  ?status:Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
# 32 "cohttp/http_daemon.mli"
val respond_error :
# 33 "cohttp/http_daemon.mli"
  ?body:string ->
# 34 "cohttp/http_daemon.mli"
  ?version:Http_types.version ->
# 35 "cohttp/http_daemon.mli"
  ?status:Http_types.status_code -> unit -> string Lwt_stream.t Lwt.t
# 36 "cohttp/http_daemon.mli"
val respond_not_found :
# 37 "cohttp/http_daemon.mli"
  url:'a ->
# 38 "cohttp/http_daemon.mli"
  ?version:Http_types.version -> unit -> string Lwt_stream.t Lwt.t
# 39 "cohttp/http_daemon.mli"
val respond_forbidden :
# 40 "cohttp/http_daemon.mli"
  url:'a ->
# 41 "cohttp/http_daemon.mli"
  ?version:Http_types.version -> unit -> string Lwt_stream.t Lwt.t
# 42 "cohttp/http_daemon.mli"
val respond_unauthorized :
# 43 "cohttp/http_daemon.mli"
  ?version:'a -> ?realm:string -> unit -> string Lwt_stream.t Lwt.t
# 44 "cohttp/http_daemon.mli"
val respond_with :
# 45 "cohttp/http_daemon.mli"
  Http_response.response -> string Lwt_stream.t Lwt.t
# 46 "cohttp/http_daemon.mli"
val daemon_callback :
# 47 "cohttp/http_daemon.mli"
  daemon_spec ->
# 48 "cohttp/http_daemon.mli"
  clisockaddr:sockaddr -> srvsockaddr:sockaddr -> OS.Flow.t -> unit Lwt.t
# 49 "cohttp/http_daemon.mli"
val main : daemon_spec -> unit Lwt.t
# 50 "cohttp/http_daemon.mli"
end = struct
# 1 "cohttp/http_daemon.ml"
(*
# 2 "cohttp/http_daemon.ml"
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon
# 3 "cohttp/http_daemon.ml"

# 4 "cohttp/http_daemon.ml"
  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
# 5 "cohttp/http_daemon.ml"
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>
# 6 "cohttp/http_daemon.ml"

# 7 "cohttp/http_daemon.ml"
  This program is free software; you can redistribute it and/or modify
# 8 "cohttp/http_daemon.ml"
  it under the terms of the GNU Library General Public License as
# 9 "cohttp/http_daemon.ml"
  published by the Free Software Foundation, version 2.
# 10 "cohttp/http_daemon.ml"

# 11 "cohttp/http_daemon.ml"
  This program is distributed in the hope that it will be useful,
# 12 "cohttp/http_daemon.ml"
  but WITHOUT ANY WARRANTY; without even the implied warranty of
# 13 "cohttp/http_daemon.ml"
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# 14 "cohttp/http_daemon.ml"
  GNU Library General Public License for more details.
# 15 "cohttp/http_daemon.ml"

# 16 "cohttp/http_daemon.ml"
  You should have received a copy of the GNU Library General Public
# 17 "cohttp/http_daemon.ml"
  License along with this program; if not, write to the Free Software
# 18 "cohttp/http_daemon.ml"
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
# 19 "cohttp/http_daemon.ml"
  USA
# 20 "cohttp/http_daemon.ml"
*)
# 21 "cohttp/http_daemon.ml"
open Printf
# 22 "cohttp/http_daemon.ml"

# 23 "cohttp/http_daemon.ml"
open Http_common
# 24 "cohttp/http_daemon.ml"
open Http_types
# 25 "cohttp/http_daemon.ml"
open Http_constants
# 26 "cohttp/http_daemon.ml"
open Http_parser
# 27 "cohttp/http_daemon.ml"

# 28 "cohttp/http_daemon.ml"
open Lwt
# 29 "cohttp/http_daemon.ml"

# 30 "cohttp/http_daemon.ml"
type conn_id = int
# 31 "cohttp/http_daemon.ml"
let string_of_conn_id = string_of_int
# 32 "cohttp/http_daemon.ml"

# 33 "cohttp/http_daemon.ml"
type daemon_spec = {
# 34 "cohttp/http_daemon.ml"
  address: string;
# 35 "cohttp/http_daemon.ml"
  auth: auth_info;
# 36 "cohttp/http_daemon.ml"
  callback: conn_id -> Http_request.request -> string Lwt_stream.t Lwt.t;
# 37 "cohttp/http_daemon.ml"
  conn_closed : conn_id -> unit;
# 38 "cohttp/http_daemon.ml"
  port: int;
# 39 "cohttp/http_daemon.ml"
  exn_handler: exn -> unit Lwt.t;
# 40 "cohttp/http_daemon.ml"
  timeout: float option;
# 41 "cohttp/http_daemon.ml"
}
# 42 "cohttp/http_daemon.ml"

# 43 "cohttp/http_daemon.ml"
exception Http_daemon_failure of string
# 44 "cohttp/http_daemon.ml"

# 45 "cohttp/http_daemon.ml"
  (** internal: given a status code and an additional body return a string
# 46 "cohttp/http_daemon.ml"
  representing an HTML document that explains the meaning of given status code.
# 47 "cohttp/http_daemon.ml"
  Additional data can be added to the body via 'body' argument *)
# 48 "cohttp/http_daemon.ml"
let control_body code body =
# 49 "cohttp/http_daemon.ml"
  let reason_phrase = Http_misc.reason_phrase_of_code code in
# 50 "cohttp/http_daemon.ml"
  sprintf "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\"><HTML><HEAD><TITLE>%d %s</TITLE></HEAD><BODY><H1>%d - %s</H1>%s</BODY></HTML>" code reason_phrase code reason_phrase body
# 51 "cohttp/http_daemon.ml"

# 52 "cohttp/http_daemon.ml"
let respond_with response =
# 53 "cohttp/http_daemon.ml"
  return (Http_response.serialize_to_stream response)
# 54 "cohttp/http_daemon.ml"

# 55 "cohttp/http_daemon.ml"
  (* Warning: keep default values in sync with Http_response.response class *)
# 56 "cohttp/http_daemon.ml"
let respond ?(body = "") ?(headers = []) ?version ?(status = `Code 200) () =
# 57 "cohttp/http_daemon.ml"
  let headers = ("connection","close")  :: headers  in
# 58 "cohttp/http_daemon.ml"
  let resp = Http_response.init ~body:[`String body] ~headers ?version ~status () in
# 59 "cohttp/http_daemon.ml"
  respond_with resp
# 60 "cohttp/http_daemon.ml"

# 61 "cohttp/http_daemon.ml"
let respond_control
# 62 "cohttp/http_daemon.ml"
    func_name ?(is_valid_status = fun _ -> true) ?(headers=[]) ?(body="")
# 63 "cohttp/http_daemon.ml"
    ?version status =
# 64 "cohttp/http_daemon.ml"
  let code = match status with `Code c -> c | #status as s -> code_of_status s in
# 65 "cohttp/http_daemon.ml"
  if is_valid_status code then
# 66 "cohttp/http_daemon.ml"
    let headers =
# 67 "cohttp/http_daemon.ml"
      [ "Content-Type", "text/html; charset=iso-8859-1" ] @ headers
# 68 "cohttp/http_daemon.ml"
    in
# 69 "cohttp/http_daemon.ml"
    let body = (control_body code body) ^ body in
# 70 "cohttp/http_daemon.ml"
      respond ?version ~status ~headers ~body ()
# 71 "cohttp/http_daemon.ml"
  else
# 72 "cohttp/http_daemon.ml"
    failwith
# 73 "cohttp/http_daemon.ml"
      (sprintf "'%d' isn't a valid status code for %s" code func_name)
# 74 "cohttp/http_daemon.ml"
      
# 75 "cohttp/http_daemon.ml"
let respond_redirect ~location ?body ?version ?(status = `Code 301) () =
# 76 "cohttp/http_daemon.ml"
  respond_control "Daemon.respond_redirect" ~is_valid_status:is_redirection
# 77 "cohttp/http_daemon.ml"
    ~headers:["Location", location] ?body ?version status
# 78 "cohttp/http_daemon.ml"

# 79 "cohttp/http_daemon.ml"
let respond_error ?body ?version ?(status = `Code 400) () =
# 80 "cohttp/http_daemon.ml"
  respond_control "Daemon.respond_error" ~is_valid_status:is_error
# 81 "cohttp/http_daemon.ml"
    ?body ?version status
# 82 "cohttp/http_daemon.ml"
    
# 83 "cohttp/http_daemon.ml"
let respond_not_found ~url ?version () =
# 84 "cohttp/http_daemon.ml"
  respond_control "Daemon.respond_not_found" ?version (`Code 404)
# 85 "cohttp/http_daemon.ml"
    
# 86 "cohttp/http_daemon.ml"
let respond_forbidden ~url ?version () =
# 87 "cohttp/http_daemon.ml"
  respond_control "Daemon.respond_forbidden" ?version (`Code 403)
# 88 "cohttp/http_daemon.ml"
    
# 89 "cohttp/http_daemon.ml"
let respond_unauthorized ?version ?(realm = server_string) () =
# 90 "cohttp/http_daemon.ml"
  let body =
# 91 "cohttp/http_daemon.ml"
    sprintf "401 - Unauthorized - Authentication failed for realm \"%s\"" realm
# 92 "cohttp/http_daemon.ml"
  in
# 93 "cohttp/http_daemon.ml"
    respond ~headers:["WWW-Authenticate", sprintf "Basic realm=\"%s\"" realm]
# 94 "cohttp/http_daemon.ml"
      ~status:(`Code 401) ~body ()
# 95 "cohttp/http_daemon.ml"

# 96 "cohttp/http_daemon.ml"
let handle_parse_exn e =
# 97 "cohttp/http_daemon.ml"
  let r =
# 98 "cohttp/http_daemon.ml"
    match e with
# 99 "cohttp/http_daemon.ml"
      | Malformed_request req ->
# 100 "cohttp/http_daemon.ml"
          Some
# 101 "cohttp/http_daemon.ml"
            (`Code 400,
# 102 "cohttp/http_daemon.ml"
             ("request 1st line format should be: " ^
# 103 "cohttp/http_daemon.ml"
		"'&lt;method&gt; &lt;url&gt; &lt;version&gt;'" ^
# 104 "cohttp/http_daemon.ml"
		"<br />\nwhile received request 1st line was:<br />\n" ^ req))
# 105 "cohttp/http_daemon.ml"
      | Invalid_HTTP_method meth ->
# 106 "cohttp/http_daemon.ml"
          Some
# 107 "cohttp/http_daemon.ml"
	    (`Code 501,
# 108 "cohttp/http_daemon.ml"
             ("Method '" ^ meth ^ "' isn't supported (yet)"))
# 109 "cohttp/http_daemon.ml"
      | Malformed_request_URI uri ->
# 110 "cohttp/http_daemon.ml"
          Some
# 111 "cohttp/http_daemon.ml"
            (`Code 400,
# 112 "cohttp/http_daemon.ml"
             ("Malformed URL: '" ^ uri ^ "'"))
# 113 "cohttp/http_daemon.ml"
      | Invalid_HTTP_version version ->
# 114 "cohttp/http_daemon.ml"
          Some
# 115 "cohttp/http_daemon.ml"
            (`Code 505,
# 116 "cohttp/http_daemon.ml"
	     ("HTTP version '" ^ version ^ "' isn't supported (yet)"))
# 117 "cohttp/http_daemon.ml"
      | Malformed_query query ->
# 118 "cohttp/http_daemon.ml"
          Some
# 119 "cohttp/http_daemon.ml"
            (`Code 400,
# 120 "cohttp/http_daemon.ml"
             (sprintf "Malformed query string '%s'" query))
# 121 "cohttp/http_daemon.ml"
      | Malformed_query_part (binding, query) ->
# 122 "cohttp/http_daemon.ml"
	  Some
# 123 "cohttp/http_daemon.ml"
            (`Code 400,
# 124 "cohttp/http_daemon.ml"
             (sprintf "Malformed query part '%s' in query '%s'" binding query))
# 125 "cohttp/http_daemon.ml"
      | _ -> None in
# 126 "cohttp/http_daemon.ml"

# 127 "cohttp/http_daemon.ml"
  match r with
# 128 "cohttp/http_daemon.ml"
    | Some (status, body) ->
# 129 "cohttp/http_daemon.ml"
        debug_print (sprintf "HTTP request parse error: %s" (Printexc.to_string e));
# 130 "cohttp/http_daemon.ml"
        respond_error ~status ~body ()
# 131 "cohttp/http_daemon.ml"
    | None ->
# 132 "cohttp/http_daemon.ml"
        fail e
# 133 "cohttp/http_daemon.ml"

# 134 "cohttp/http_daemon.ml"
  (** - handle HTTP authentication
# 135 "cohttp/http_daemon.ml"
   *  - handle automatic closures of client connections *)
# 136 "cohttp/http_daemon.ml"
let invoke_callback conn_id (req:Http_request.request) spec =
# 137 "cohttp/http_daemon.ml"
  try_lwt 
# 138 "cohttp/http_daemon.ml"
    (match (spec.auth, (Http_request.authorization req)) with
# 139 "cohttp/http_daemon.ml"
       | `None, _ -> spec.callback conn_id req (* no auth required *)
# 140 "cohttp/http_daemon.ml"
       | `Basic (realm, authfn), Some (`Basic (username, password)) ->
# 141 "cohttp/http_daemon.ml"
	   if authfn username password then spec.callback conn_id req (* auth ok *)
# 142 "cohttp/http_daemon.ml"
	   else fail (Unauthorized realm)
# 143 "cohttp/http_daemon.ml"
       | `Basic (realm, _), _ -> fail (Unauthorized realm)) (* auth failure *)
# 144 "cohttp/http_daemon.ml"
  with
# 145 "cohttp/http_daemon.ml"
    | Unauthorized realm -> respond_unauthorized ~realm ()
# 146 "cohttp/http_daemon.ml"
    | e ->
# 147 "cohttp/http_daemon.ml"
        respond_error ~status:`Internal_server_error ~body:(Printexc.to_string e) ()
# 148 "cohttp/http_daemon.ml"

# 149 "cohttp/http_daemon.ml"
let daemon_callback spec =
# 150 "cohttp/http_daemon.ml"
  let conn_id = ref 0 in
# 151 "cohttp/http_daemon.ml"
  let daemon_callback ~clisockaddr ~srvsockaddr flow =
# 152 "cohttp/http_daemon.ml"
    let conn_id = incr conn_id; !conn_id in
# 153 "cohttp/http_daemon.ml"

# 154 "cohttp/http_daemon.ml"
    let streams, push_streams = Lwt_stream.create () in
# 155 "cohttp/http_daemon.ml"
    let write_streams =
# 156 "cohttp/http_daemon.ml"
      try_lwt
# 157 "cohttp/http_daemon.ml"
        Lwt_stream.iter_s (fun stream_t ->
# 158 "cohttp/http_daemon.ml"
          lwt stream = stream_t in
# 159 "cohttp/http_daemon.ml"
          (* Temporary until buffered IO *)
# 160 "cohttp/http_daemon.ml"
          let output = Buffer.create 4096 in
# 161 "cohttp/http_daemon.ml"
          Lwt_stream.iter (Buffer.add_string output) stream >>
# 162 "cohttp/http_daemon.ml"
          OS.Flow.write_all flow (Buffer.contents output))
# 163 "cohttp/http_daemon.ml"
        streams
# 164 "cohttp/http_daemon.ml"
      with _ -> return ()
# 165 "cohttp/http_daemon.ml"
    in
# 166 "cohttp/http_daemon.ml"
    let rec loop () =
# 167 "cohttp/http_daemon.ml"
      try_lwt
# 168 "cohttp/http_daemon.ml"
        let (finished_t, finished_u) = Lwt.wait () in
# 169 "cohttp/http_daemon.ml"

# 170 "cohttp/http_daemon.ml"
        let stream =
# 171 "cohttp/http_daemon.ml"
          try_lwt
# 172 "cohttp/http_daemon.ml"
            lwt req = Http_request.init_request ~clisockaddr ~srvsockaddr finished_u flow in
# 173 "cohttp/http_daemon.ml"
            invoke_callback conn_id req spec
# 174 "cohttp/http_daemon.ml"
          with e -> begin
# 175 "cohttp/http_daemon.ml"
            try_lwt
# 176 "cohttp/http_daemon.ml"
              lwt s = handle_parse_exn e in
# 177 "cohttp/http_daemon.ml"
              wakeup finished_u (); (* read another request *)
# 178 "cohttp/http_daemon.ml"
              return s
# 179 "cohttp/http_daemon.ml"
            with e ->
# 180 "cohttp/http_daemon.ml"
              wakeup_exn finished_u e;
# 181 "cohttp/http_daemon.ml"
              fail e
# 182 "cohttp/http_daemon.ml"
          end
# 183 "cohttp/http_daemon.ml"
        in
# 184 "cohttp/http_daemon.ml"
        push_streams (Some stream);
# 185 "cohttp/http_daemon.ml"
        finished_t >>= loop (* wait for request to finish before reading another *)
# 186 "cohttp/http_daemon.ml"
      with
# 187 "cohttp/http_daemon.ml"
        | End_of_file -> debug_print "done with connection"; spec.conn_closed conn_id; return ()
# 188 "cohttp/http_daemon.ml"
        | Canceled -> debug_print "cancelled"; spec.conn_closed conn_id; return ()
# 189 "cohttp/http_daemon.ml"
        | e -> fail e
# 190 "cohttp/http_daemon.ml"
    in
# 191 "cohttp/http_daemon.ml"
    try_lwt
# 192 "cohttp/http_daemon.ml"
      loop () <&> write_streams
# 193 "cohttp/http_daemon.ml"
    with
# 194 "cohttp/http_daemon.ml"
      | exn ->
# 195 "cohttp/http_daemon.ml"
	  debug_print (sprintf "uncaught exception: %s" (Printexc.to_string exn));
# 196 "cohttp/http_daemon.ml"
          (* XXX perhaps there should be a higher-level exn handler for 500s *)
# 197 "cohttp/http_daemon.ml"
	  spec.exn_handler exn
# 198 "cohttp/http_daemon.ml"
  in
# 199 "cohttp/http_daemon.ml"
  daemon_callback
# 200 "cohttp/http_daemon.ml"

# 201 "cohttp/http_daemon.ml"
let main spec =
# 202 "cohttp/http_daemon.ml"
  lwt srvsockaddr = Http_misc.build_sockaddr (spec.address, spec.port) in
# 203 "cohttp/http_daemon.ml"
  OS.Flow.listen (fun clisockaddr flow ->
# 204 "cohttp/http_daemon.ml"
      match spec.timeout with
# 205 "cohttp/http_daemon.ml"
      | None -> daemon_callback spec ~clisockaddr ~srvsockaddr flow
# 206 "cohttp/http_daemon.ml"
      | Some tm -> daemon_callback spec ~clisockaddr ~srvsockaddr flow <?> (OS.Time.sleep tm)
# 207 "cohttp/http_daemon.ml"
  ) srvsockaddr
# 208 "cohttp/http_daemon.ml"
end
