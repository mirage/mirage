
(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
  Copyright (C) <2009> Anil Madhavapeddy <anil@recoil.org>

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

open Types;;
open Printf;;

let string_of_version = function
  | `HTTP_1_0 -> "HTTP/1.0"
  | `HTTP_1_1 -> "HTTP/1.1"

let version_of_string = function
  | "HTTP/1.0" -> `HTTP_1_0
  | "HTTP/1.1" -> `HTTP_1_1
  | invalid_version -> raise (Invalid_HTTP_version invalid_version)

let string_of_method = function
  | `GET -> "GET"
  | `POST -> "POST"
  | `HEAD -> "HEAD"
  | `DELETE -> "DELETE"

let method_of_string = function
  | "GET" -> `GET
  | "POST" -> `POST
  | "HEAD" -> `HEAD
  | "DELETE" -> `DELETE
  | invalid_method -> raise (Invalid_HTTP_method invalid_method)

let status_of_code = function
  | 100 -> `Continue
  | 101 -> `Switching_protocols
  | 200 -> `OK
  | 201 -> `Created
  | 202 -> `Accepted
  | 203 -> `Non_authoritative_information
  | 204 -> `No_content
  | 205 -> `Reset_content
  | 206 -> `Partial_content
  | 300 -> `Multiple_choices
  | 301 -> `Moved_permanently
  | 302 -> `Found
  | 303 -> `See_other
  | 304 -> `Not_modified
  | 305 -> `Use_proxy
  | 307 -> `Temporary_redirect
  | 400 -> `Bad_request
  | 401 -> `Unauthorized
  | 402 -> `Payment_required
  | 403 -> `Forbidden
  | 404 -> `Not_found
  | 405 -> `Method_not_allowed
  | 406 -> `Not_acceptable
  | 407 -> `Proxy_authentication_required
  | 408 -> `Request_time_out
  | 409 -> `Conflict
  | 410 -> `Gone
  | 411 -> `Length_required
  | 412 -> `Precondition_failed
  | 413 -> `Request_entity_too_large
  | 414 -> `Request_URI_too_large
  | 415 -> `Unsupported_media_type
  | 416 -> `Requested_range_not_satisfiable
  | 417 -> `Expectation_failed
  | 500 -> `Internal_server_error
  | 501 -> `Not_implemented
  | 502 -> `Bad_gateway
  | 503 -> `Service_unavailable
  | 504 -> `Gateway_time_out
  | 505 -> `HTTP_version_not_supported
  | invalid_code -> raise (Invalid_code invalid_code)

let code_of_status = function
  | `Continue -> 100
  | `Switching_protocols -> 101
  | `OK -> 200
  | `Created -> 201
  | `Accepted -> 202
  | `Non_authoritative_information -> 203
  | `No_content -> 204
  | `Reset_content -> 205
  | `Partial_content -> 206
  | `Multiple_choices -> 300
  | `Moved_permanently -> 301
  | `Found -> 302
  | `See_other -> 303
  | `Not_modified -> 304
  | `Use_proxy -> 305
  | `Temporary_redirect -> 307
  | `Bad_request -> 400
  | `Unauthorized -> 401
  | `Payment_required -> 402
  | `Forbidden -> 403
  | `Not_found -> 404
  | `Method_not_allowed -> 405
  | `Not_acceptable -> 406
  | `Proxy_authentication_required -> 407
  | `Request_time_out -> 408
  | `Conflict -> 409
  | `Gone -> 410
  | `Length_required -> 411
  | `Precondition_failed -> 412
  | `Request_entity_too_large -> 413
  | `Request_URI_too_large -> 414
  | `Unsupported_media_type -> 415
  | `Requested_range_not_satisfiable -> 416
  | `Expectation_failed -> 417
  | `Internal_server_error -> 500
  | `Not_implemented -> 501
  | `Bad_gateway -> 502
  | `Service_unavailable -> 503
  | `Gateway_time_out -> 504
  | `HTTP_version_not_supported -> 505

let is_informational code =
  match status_of_code code with
  | #informational_status -> true
  | _ -> false

let is_success code =
  match status_of_code code with
  | #success_status -> true
  | _ -> false

let is_redirection code =
  match status_of_code code with
  | #redirection_status -> true
  | _ -> false

let is_client_error code =
  match status_of_code code with
  | #client_error_status -> true
  | _ -> false

let is_server_error code =
  match status_of_code code with
  | #server_error_status -> true
  | _ -> false

let is_error code = is_client_error code || is_server_error code

