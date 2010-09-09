(*
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(* http://tools.ietf.org/id/draft-ietf-hybi-thewebsocketprotocol-01.html *)

open Lwt
open Mlnet_types
open Printf

let (>>) f g = g x

exception Invalid_state_err
exception Parse_error of string


(* TODO: use env insted of string *)
module Handshake = struct
  (* ============================================================ *)
  (* opening handshake                                            *)
  (* ============================================================ *)
  
  (* client query *)
  type query = {
    path : string;
    protocol : string list;
    host : string option;
    origin : string option;
    key1 : string;
    key2 : string;
    body : string;
    query : string; (* the complete query string *)
  }

  (* server response *)
  type response = {
    r_protocol : string list;
    r_host : string option;
    r_origin : string option;
    r_challenge : string;
  }

  let assoc_option a l =
    if List.mem_assoc a l then
      Some (List.assoc a l)
    else
      None

  let assoc_list a l =
    if List.mem_assoc a l then
      Str.split (Str.regexp " \t+") (List.assoc a l)
    else
      []

  let is_valid_query pairs body =
       List.mem_assoc "Upgrade" pairs
    && List.assoc "Upgrade" pairs = "WebSocket"
    && List.mem_assoc "Connection" pairs
    && List.assoc "Connection" pairs = "Upgrade"
    && List.mem_assoc "Sec-WebSocket-Key1" pairs
    && List.mem_assoc "Sec-WebSocket-Key2" pairs
    && String.length body = 8

  let parse_error str = raise (Parse_error str)

  let query_of_string str =
    match Str.split (Str.regexp "\n+") hd with
    | head :: t ->
        let path =
          try Scanf.sprintf head "GET /%s HTTP/1.1" (fun s -> s)
          with _ -> parse_error str in
        begin match List.rev t with
        | body :: "\r" :: "\r" :: pairs ->
            let pairs =
              List.rev_map (fun s ->
                match Str.bounded_split (Str.regexp "[ \t:]+") 1 s with
                | [ key; value ] -> (key, value)
                | _              -> parse_error str)
                pairs in
            if not (is_valid_query pairs body) then
              parse_error str;
            let protocols = assoc_list   "Sec-WebSocket-Protocol" pairs in
            let host      = assoc_option "Host"                   pairs in
            let origin    = assoc_option "Origin"                 pairs in
            let key1      = List.assoc   "Sec-WebSocket-Key1"     pairs in
            let key2      = List.assoc   "Sec-WebSocket-Key2"     pairs in
            let query     = str in
            { path; protocols; host; origin; key1; key2; body; query }
        | _ -> parse_error str
        end
    | _ -> parse_error str
            
  let compute_challenge query =
    let fold fn step0 s =
	    let res = ref step0 in
	    for i = 0 to String.length s - 1 do
		    res := fn !res s.[i]
	    done;
	    !res in
	  let get_nb accu c =
		  if c >= '0' && c <= '9' then
			  (accu * 10) + int_of_char c
		  else
			  accu in
	  let get_blank accu c =
		  if c = ' ' then
			  accu + 1
		  else
			  accu in
	  let digits1 = fold get_nb    0 query.key1 in
	  let digits2 = fold get_nb    0 query.key2 in
	  let blank1  = fold get_blank 0 query.key1 in
	  let blank2  = fold get_blank 0 query.key2 in
	  if blank1 = 0 || blank2 = 0 then parse_error query.query
	let return1 = digits1 / blank1 in
	let return2 = digits2 / blank2 in
	let return  = string_of_int return1 ^ string_of_int return2 ^ client.key3 in
	let digest  = Digest.string return in
	Digest.to_hex digest

  let response_of_query query =
    let challenge = compute_challenge query in
    { r_protocols = query.protocols;
      r_host = query.host;
      r_origin = query.origin;
      challenge }
    
  let string_of_response response =
    let headers = "HTTP/1.1 101 WebSocket Protocol Handshake\nUpgrade: WebSocket\nConnection: Upgrade" in
    let origin = match response.r_origin with
      | Some o -> "Sec-WebSocket-Origin: " ^ o
      | None   -> "" in
    let location = match response.r_host with
      | Some o -> "Sec-WebSocket-Location: " ^ o
      | None   -> "" in
    String.concat "\n" [ headers ; origin ; location ; "\r\n\r" ; response.challenge ]

  let process str =
    query_of_string str >>
    response_of_query >>
    string_of_response
end

module Server(IP:Ipv4.UP)(TCP:Tcp.UP) = struct

  type state =
  | Connecting
  | Open
  | Closing
  | Closed

  type connection = {
    host : string;
    port : int;
    resource : string option;
    secure : bool;
        
  type t = {
    ip : IP.t;
    tcp : TCP.t;
    listeners : (Mpl.Ipv4.o -> Mpl.Tcp.o -> Mpl.Websocket.o -> unit Lwt.t) list;
  }
  

  let output t ~dest_ip ws =
   match ws.ready_state with
   | Connecting -> raise Invalid_state_err
   | Closing | Closed -> ()
   | Open -> (* TODO *) ()
      

  let close t =
   match ws.ready_state with
   | Closing | Closed -> ()
   | Connecting ->
	   ws.ready_state <- Closing;
	   (* TODO: fail the websocket connection *)
	   ws.ready_state <- Closed
   | Open ->
	   ws.ready_state <- Closed
