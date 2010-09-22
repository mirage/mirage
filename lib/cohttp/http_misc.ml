(*pp camlp4o -I `ocamlfind query lwt.syntax` pa_lwt.cmo *)

(*
  OCaml HTTP - do it yourself (fully OCaml) HTTP daemon

  Copyright (C) <2002-2005> Stefano Zacchiroli <zack@cs.unibo.it>
	              2006-2009 Citrix Systems Inc.
	              2010 Thomas Gazagnaire <thomas@gazagnaire.com>

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

module OS = Unix

open Printf
open Lwt

open Http_types
open Mlnet.Types

let months = [| "Jan"; "Feb"; "Mar"; "Apr"; "May"; "Jun"; 
   							"Jul"; "Aug"; "Sep"; "Oct"; "Nov"; "Dec" |]
let days = [| "Sun"; "Mon"; "Tue"; "Wed"; "Thu"; "Fri"; "Sat" |]

let rfc822_of_float x =
  let time = OS.Clock.gmtime x in
  Printf.sprintf "%s, %d %s %d %02d:%02d:%02d GMT"
    days.(time.OS.Clock.tm_wday) time.OS.Clock.tm_mday
    months.(time.OS.Clock.tm_mon) (time.OS.Clock.tm_year+1900)
    time.OS.Clock.tm_hour time.OS.Clock.tm_min time.OS.Clock.tm_sec

let date_822 () =
  rfc822_of_float (OS.Clock.time ())

let strip_trailing_slash s =
  match String.length s with
  |0 -> s
  |n -> if s.[n-1] = '/' then String.sub s 0 (n-1) else s

let strip_heading_slash s =
  match String.length s with
  |0 -> s
  |n -> if s.[0] = '/' then String.sub s 1 (n-1) else s

let string_explode s =
  let rec string_explode' acc = function
    | "" -> acc
    | s -> string_explode' (s.[0] :: acc) (String.sub s 1 (String.length s - 1))
  in
  List.rev (string_explode' [] s)

let string_implode = List.fold_left (fun s c -> s ^ (String.make 1 c)) ""

let reason_phrase_of_code = function
  | 100 -> "Continue"
  | 101 -> "Switching protocols"
  | 200 -> "OK"
  | 201 -> "Created"
  | 202 -> "Accepted"
  | 203 -> "Non authoritative information"
  | 204 -> "No content"
  | 205 -> "Reset content"
  | 206 -> "Partial content"
  | 300 -> "Multiple choices"
  | 301 -> "Moved permanently"
  | 302 -> "Found"
  | 303 -> "See other"
  | 304 -> "Not modified"
  | 305 -> "Use proxy"
  | 307 -> "Temporary redirect"
  | 400 -> "Bad request"
  | 401 -> "Unauthorized"
  | 402 -> "Payment required"
  | 403 -> "Forbidden"
  | 404 -> "Not found"
  | 405 -> "Method not allowed"
  | 406 -> "Not acceptable"
  | 407 -> "Proxy authentication required"
  | 408 -> "Request time out"
  | 409 -> "Conflict"
  | 410 -> "Gone"
  | 411 -> "Length required"
  | 412 -> "Precondition failed"
  | 413 -> "Request entity too large"
  | 414 -> "Request URI too large"
  | 415 -> "Unsupported media type"
  | 416 -> "Requested range not satisfiable"
  | 417 -> "Expectation failed"
  | 500 -> "Internal server error"
  | 501 -> "Not implemented"
  | 502 -> "Bad gateway"
  | 503 -> "Service unavailable"
  | 504 -> "Gateway time out"
  | 505 -> "HTTP version not supported"
  | invalid_code -> raise (Invalid_code invalid_code)

let build_sockaddr (addr, port) =
  try_lwt
    (* should this be lwt hent = Lwt_lib.gethostbyname addr ? *)
    (* XXX: no DNS client at the moment *)
    (* let hent = Unix.gethostbyname addr in *)
    (* return (Unix.ADDR_INET (hent.Unix.h_addr_list.(0), port)) *)
    let ip = match Mlnet.Types.ipv4_addr_of_string addr with
      | Some x -> x
      | None -> failwith "ip" in
    return (TCP (ip, port))
  with _ -> failwith ("ocaml-cohttp, cant resolve hostname: " ^ addr)
     
let explode_sockaddr = function
  | TCP (ip, port) -> (Mlnet.Types.ipv4_addr_to_string ip, port)
  | _ -> assert false (* can explode only inet address *)

let list_assoc_all key pairs =
  snd (List.split (List.filter (fun (k, v) -> k = key) pairs))

let warn msg  = prerr_endline (sprintf "ocaml-cohttp WARNING: %s" msg)
let error msg = prerr_endline (sprintf "ocaml-cohttp ERROR:   %s" msg)
