
(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>

  This program is free software; you can redistribute it and/or modify
  it under the terms of the GNU Library General Public License as
  published by the Free Software Foundation, version 2.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public
  License along with this program; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
  USA
*)

(** Type definitions *)

  (** HTTP version, actually only 1.0 and 1.1 are supported. Note that
  'supported' here means only 'accepted inside a HTTP request line', no
  different behaviours are actually implemented depending on HTTP version *)
type version =
  [ `HTTP_1_0
  | `HTTP_1_1
  ]

  (** HTTP method, actually only GET and POST methods are supported *)
type meth =
  [ `GET
  | `POST
  | `HEAD
  | `DELETE
  ]

  (** authentication information *)
type auth_info =
  [ `None
  | `Basic of string * (string -> string -> bool) (* realm, user -> pass -> bool *)
(*| `Digest of ...  (* TODO digest authentication *) *)
  ]

  (** @see "RFC2616" informational HTTP status *)
type informational_status =
  [ `Continue
  | `Switching_protocols
  ]

  (** @see "RFC2616" success HTTP status *)
type success_status =
  [ `OK
  | `Created
  | `Accepted
  | `Non_authoritative_information
  | `No_content
  | `Reset_content
  | `Partial_content
  ]

  (** @see "RFC2616" redirection HTTP status *)
type redirection_status =
  [ `Multiple_choices
  | `Moved_permanently
  | `Found
  | `See_other
  | `Not_modified
  | `Use_proxy
  | `Temporary_redirect
  ]

  (** @see "RFC2616" client error HTTP status *)
type client_error_status =
  [ `Bad_request
  | `Unauthorized
  | `Payment_required
  | `Forbidden
  | `Not_found
  | `Method_not_allowed
  | `Not_acceptable
  | `Proxy_authentication_required
  | `Request_time_out
  | `Conflict
  | `Gone
  | `Length_required
  | `Precondition_failed
  | `Request_entity_too_large
  | `Request_URI_too_large
  | `Unsupported_media_type
  | `Requested_range_not_satisfiable
  | `Expectation_failed
  ]

  (** @see "RFC2616" server error HTTP status *)
type server_error_status =
  [ `Internal_server_error
  | `Not_implemented
  | `Bad_gateway
  | `Service_unavailable
  | `Gateway_time_out
  | `HTTP_version_not_supported
  ]

type error_status =
  [ client_error_status
  | server_error_status
  ]

  (** HTTP status *)
type status =
  [ informational_status
  | success_status
  | redirection_status
  | client_error_status
  | server_error_status
  ]

type status_code = [ `Code of int | status ]

  (** {2 Exceptions} *)

  (** invalid header encountered *)
exception Invalid_header of string

  (** invalid header name encountered *)
exception Invalid_header_name of string

  (** invalid header value encountered *)
exception Invalid_header_value of string

  (** unsupported or invalid HTTP version encountered *)
exception Invalid_HTTP_version of string

  (** unsupported or invalid HTTP method encountered *)
exception Invalid_HTTP_method of string

  (** invalid HTTP status code integer representation encountered *)
exception Invalid_code of int

  (** invalid URL encountered *)
exception Malformed_URL of string

  (** invalid query string encountered *)
exception Malformed_query of string

  (** invalid query string part encountered, arguments are parameter name and
  parameter value *)
exception Malformed_query_part of string * string

  (** invalid request URI encountered *)
exception Malformed_request_URI of string

  (** malformed request received *)
exception Malformed_request of string

  (** malformed response received, argument is response's first line *)
exception Malformed_response of string

  (** a parameter you were looking for was not found *)
exception Param_not_found of string

  (** invalid HTTP status line encountered *)
exception Invalid_status_line of string

  (** an header you were looking for was not found *)
exception Header_not_found of string

  (** raisable by callbacks to force a 401 (unauthorized) HTTP answer.
      This exception should be raised _before_ sending any data over given out
      channel.
      @param realm authentication realm (usually needed to prompt user) *)
exception Unauthorized of string
