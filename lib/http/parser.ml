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

open Printf
open Lwt

open Common
open Types
open Constants

let bindings_sep, binding_sep, pieces_sep, header_sep =
  Str.(regexp_string "&", regexp_string "=", 
       regexp_string " ", regexp_string ":" )

let header_RE = Str.regexp "([^:]*):(.*)"

let url_decode url = Url.decode url

let split_query_params query =
  let bindings = Str.split bindings_sep query in
  match bindings with
  | [] -> raise (Malformed_query query)
  | bindings ->
      List.map
        (fun binding ->
          match Str.split binding_sep binding with
          | [ ""; b ] -> (* '=b' *)
              raise (Malformed_query_part (binding, query))
          | [ a; b ]  -> (* 'a=b' *) (url_decode a, url_decode b)
          | [ a ]     -> (* 'a=' || 'a' *) (url_decode a, "")
          | _ -> raise (Malformed_query_part (binding, query)))
        bindings

let debug_dump_request path params =
  debug_print
    (sprintf
      "recevied request; path: %s; params: %s"
      path
      (String.concat ", " (List.map (fun (n, v) -> n ^ "=" ^ v) params)))

let parse_request_fst_line ic =
  debug_print "parse_request_fst_line";
  lwt request_line = ic () in
  debug_print (sprintf "HTTP request line (not yet parsed): %s" request_line);
  try_lwt begin
    match Str.split pieces_sep request_line with
      | [ meth_raw; uri_raw; http_version_raw ] ->
          return (method_of_string meth_raw,
		  Url.of_string uri_raw,
		  version_of_string http_version_raw)
      | _ -> fail (Malformed_request request_line)
  end with | Malformed_URL url -> fail (Malformed_request_URI url)

let parse_response_fst_line ic =
  lwt response_line = ic () in
  debug_print (sprintf "HTTP response line (not yet parsed): %s" response_line);
  try_lwt
    (match Str.split pieces_sep response_line with
    | version_raw :: code_raw :: _ ->
        debug_print (Printf.sprintf "version_raw=%s; code_raw=%s" version_raw code_raw);
        return (version_of_string version_raw,      (* method *)
        status_of_code (int_of_string code_raw))    (* status *)
    | _ ->
		debug_print "Malformed_response";
		fail (Malformed_response response_line))
  with 
  | Malformed_URL _ | Invalid_code _ | Failure "int_of_string" ->
     fail (Malformed_response response_line)
  | e -> fail e

let parse_path uri = match Url.path uri with None -> "/" | Some x -> x

let parse_query_get_params uri =
  try (* act on HTTP encoded URIs *)
    match Url.query uri with None -> [] | Some x -> split_query_params x
  with Not_found -> []

let parse_headers ic =
  (* consume also trailing "^\r\n$" line *)
  let rec parse_headers' headers =
    ic () >>= function
    | "" -> return (List.rev headers)
    | line -> begin
        match Str.(bounded_split (regexp_string ":") line 2) with
        | [header; value] ->
            lwt norm_value =
              try_lwt 
                return (Parser_sanity.normalize_header_value value)
              with _ -> return "" in
            parse_headers' ((String.lowercase header, norm_value) :: headers)
        | _ -> fail (Invalid_header line) 
      end
  in
  parse_headers' []

let parse_request ic =
  debug_print "parse_request";
  lwt (meth, uri, version) = parse_request_fst_line ic in
  let path = parse_path uri in
  let query_get_params = parse_query_get_params uri in
  debug_dump_request path query_get_params;
  return (path, query_get_params)

