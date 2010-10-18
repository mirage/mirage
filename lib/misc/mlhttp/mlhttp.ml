(* This file has been auto-generated using ocamlpack and includes:
      websocket.ml
 *)

module Websocket = struct
# 1 "mlhttp/websocket.ml"
(*
# 2 "mlhttp/websocket.ml"
 * Copyright (c) 2010 Thomas Gazagnaire <thomas@gazagnaire.com>
# 3 "mlhttp/websocket.ml"
 *
# 4 "mlhttp/websocket.ml"
 * Permission to use, copy, modify, and distribute this software for any
# 5 "mlhttp/websocket.ml"
 * purpose with or without fee is hereby granted, provided that the above
# 6 "mlhttp/websocket.ml"
 * copyright notice and this permission notice appear in all copies.
# 7 "mlhttp/websocket.ml"
 *
# 8 "mlhttp/websocket.ml"
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# 9 "mlhttp/websocket.ml"
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# 10 "mlhttp/websocket.ml"
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# 11 "mlhttp/websocket.ml"
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# 12 "mlhttp/websocket.ml"
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# 13 "mlhttp/websocket.ml"
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# 14 "mlhttp/websocket.ml"
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 15 "mlhttp/websocket.ml"
 *)
# 16 "mlhttp/websocket.ml"

# 17 "mlhttp/websocket.ml"
(* http://tools.ietf.org/id/draft-ietf-hybi-thewebsocketprotocol-01.html *)
# 18 "mlhttp/websocket.ml"

# 19 "mlhttp/websocket.ml"
open Lwt
# 20 "mlhttp/websocket.ml"
open Mlnet_types
# 21 "mlhttp/websocket.ml"
open Printf
# 22 "mlhttp/websocket.ml"

# 23 "mlhttp/websocket.ml"
let (>>) f g = g x
# 24 "mlhttp/websocket.ml"

# 25 "mlhttp/websocket.ml"
exception Invalid_state_err
# 26 "mlhttp/websocket.ml"
exception Parse_error of string
# 27 "mlhttp/websocket.ml"

# 28 "mlhttp/websocket.ml"

# 29 "mlhttp/websocket.ml"
(* TODO: use env insted of string *)
# 30 "mlhttp/websocket.ml"
module Handshake = struct
# 31 "mlhttp/websocket.ml"
  (* ============================================================ *)
# 32 "mlhttp/websocket.ml"
  (* opening handshake                                            *)
# 33 "mlhttp/websocket.ml"
  (* ============================================================ *)
# 34 "mlhttp/websocket.ml"
  
# 35 "mlhttp/websocket.ml"
  (* client query *)
# 36 "mlhttp/websocket.ml"
  type query = {
# 37 "mlhttp/websocket.ml"
    path : string;
# 38 "mlhttp/websocket.ml"
    protocol : string list;
# 39 "mlhttp/websocket.ml"
    host : string option;
# 40 "mlhttp/websocket.ml"
    origin : string option;
# 41 "mlhttp/websocket.ml"
    key1 : string;
# 42 "mlhttp/websocket.ml"
    key2 : string;
# 43 "mlhttp/websocket.ml"
    body : string;
# 44 "mlhttp/websocket.ml"
    query : string; (* the complete query string *)
# 45 "mlhttp/websocket.ml"
  }
# 46 "mlhttp/websocket.ml"

# 47 "mlhttp/websocket.ml"
  (* server response *)
# 48 "mlhttp/websocket.ml"
  type response = {
# 49 "mlhttp/websocket.ml"
    r_protocol : string list;
# 50 "mlhttp/websocket.ml"
    r_host : string option;
# 51 "mlhttp/websocket.ml"
    r_origin : string option;
# 52 "mlhttp/websocket.ml"
    r_challenge : string;
# 53 "mlhttp/websocket.ml"
  }
# 54 "mlhttp/websocket.ml"

# 55 "mlhttp/websocket.ml"
  let assoc_option a l =
# 56 "mlhttp/websocket.ml"
    if List.mem_assoc a l then
# 57 "mlhttp/websocket.ml"
      Some (List.assoc a l)
# 58 "mlhttp/websocket.ml"
    else
# 59 "mlhttp/websocket.ml"
      None
# 60 "mlhttp/websocket.ml"

# 61 "mlhttp/websocket.ml"
  let assoc_list a l =
# 62 "mlhttp/websocket.ml"
    if List.mem_assoc a l then
# 63 "mlhttp/websocket.ml"
      Str.split (Str.regexp " \t+") (List.assoc a l)
# 64 "mlhttp/websocket.ml"
    else
# 65 "mlhttp/websocket.ml"
      []
# 66 "mlhttp/websocket.ml"

# 67 "mlhttp/websocket.ml"
  let is_valid_query pairs body =
# 68 "mlhttp/websocket.ml"
       List.mem_assoc "Upgrade" pairs
# 69 "mlhttp/websocket.ml"
    && List.assoc "Upgrade" pairs = "WebSocket"
# 70 "mlhttp/websocket.ml"
    && List.mem_assoc "Connection" pairs
# 71 "mlhttp/websocket.ml"
    && List.assoc "Connection" pairs = "Upgrade"
# 72 "mlhttp/websocket.ml"
    && List.mem_assoc "Sec-WebSocket-Key1" pairs
# 73 "mlhttp/websocket.ml"
    && List.mem_assoc "Sec-WebSocket-Key2" pairs
# 74 "mlhttp/websocket.ml"
    && String.length body = 8
# 75 "mlhttp/websocket.ml"

# 76 "mlhttp/websocket.ml"
  let parse_error str = raise (Parse_error str)
# 77 "mlhttp/websocket.ml"

# 78 "mlhttp/websocket.ml"
  let query_of_string str =
# 79 "mlhttp/websocket.ml"
    match Str.split (Str.regexp "\n+") hd with
# 80 "mlhttp/websocket.ml"
    | head :: t ->
# 81 "mlhttp/websocket.ml"
        let path =
# 82 "mlhttp/websocket.ml"
          try Scanf.sprintf head "GET /%s HTTP/1.1" (fun s -> s)
# 83 "mlhttp/websocket.ml"
          with _ -> parse_error str in
# 84 "mlhttp/websocket.ml"
        begin match List.rev t with
# 85 "mlhttp/websocket.ml"
        | body :: "\r" :: "\r" :: pairs ->
# 86 "mlhttp/websocket.ml"
            let pairs =
# 87 "mlhttp/websocket.ml"
              List.rev_map (fun s ->
# 88 "mlhttp/websocket.ml"
                match Str.bounded_split (Str.regexp "[ \t:]+") 1 s with
# 89 "mlhttp/websocket.ml"
                | [ key; value ] -> (key, value)
# 90 "mlhttp/websocket.ml"
                | _              -> parse_error str)
# 91 "mlhttp/websocket.ml"
                pairs in
# 92 "mlhttp/websocket.ml"
            if not (is_valid_query pairs body) then
# 93 "mlhttp/websocket.ml"
              parse_error str;
# 94 "mlhttp/websocket.ml"
            let protocols = assoc_list   "Sec-WebSocket-Protocol" pairs in
# 95 "mlhttp/websocket.ml"
            let host      = assoc_option "Host"                   pairs in
# 96 "mlhttp/websocket.ml"
            let origin    = assoc_option "Origin"                 pairs in
# 97 "mlhttp/websocket.ml"
            let key1      = List.assoc   "Sec-WebSocket-Key1"     pairs in
# 98 "mlhttp/websocket.ml"
            let key2      = List.assoc   "Sec-WebSocket-Key2"     pairs in
# 99 "mlhttp/websocket.ml"
            let query     = str in
# 100 "mlhttp/websocket.ml"
            { path; protocols; host; origin; key1; key2; body; query }
# 101 "mlhttp/websocket.ml"
        | _ -> parse_error str
# 102 "mlhttp/websocket.ml"
        end
# 103 "mlhttp/websocket.ml"
    | _ -> parse_error str
# 104 "mlhttp/websocket.ml"
            
# 105 "mlhttp/websocket.ml"
  let compute_challenge query =
# 106 "mlhttp/websocket.ml"
    let fold fn step0 s =
# 107 "mlhttp/websocket.ml"
	    let res = ref step0 in
# 108 "mlhttp/websocket.ml"
	    for i = 0 to String.length s - 1 do
# 109 "mlhttp/websocket.ml"
		    res := fn !res s.[i]
# 110 "mlhttp/websocket.ml"
	    done;
# 111 "mlhttp/websocket.ml"
	    !res in
# 112 "mlhttp/websocket.ml"
	  let get_nb accu c =
# 113 "mlhttp/websocket.ml"
		  if c >= '0' && c <= '9' then
# 114 "mlhttp/websocket.ml"
			  (accu * 10) + int_of_char c
# 115 "mlhttp/websocket.ml"
		  else
# 116 "mlhttp/websocket.ml"
			  accu in
# 117 "mlhttp/websocket.ml"
	  let get_blank accu c =
# 118 "mlhttp/websocket.ml"
		  if c = ' ' then
# 119 "mlhttp/websocket.ml"
			  accu + 1
# 120 "mlhttp/websocket.ml"
		  else
# 121 "mlhttp/websocket.ml"
			  accu in
# 122 "mlhttp/websocket.ml"
	  let digits1 = fold get_nb    0 query.key1 in
# 123 "mlhttp/websocket.ml"
	  let digits2 = fold get_nb    0 query.key2 in
# 124 "mlhttp/websocket.ml"
	  let blank1  = fold get_blank 0 query.key1 in
# 125 "mlhttp/websocket.ml"
	  let blank2  = fold get_blank 0 query.key2 in
# 126 "mlhttp/websocket.ml"
	  if blank1 = 0 || blank2 = 0 then parse_error query.query
# 127 "mlhttp/websocket.ml"
	let return1 = digits1 / blank1 in
# 128 "mlhttp/websocket.ml"
	let return2 = digits2 / blank2 in
# 129 "mlhttp/websocket.ml"
	let return  = string_of_int return1 ^ string_of_int return2 ^ client.key3 in
# 130 "mlhttp/websocket.ml"
	let digest  = Digest.string return in
# 131 "mlhttp/websocket.ml"
	Digest.to_hex digest
# 132 "mlhttp/websocket.ml"

# 133 "mlhttp/websocket.ml"
  let response_of_query query =
# 134 "mlhttp/websocket.ml"
    let challenge = compute_challenge query in
# 135 "mlhttp/websocket.ml"
    { r_protocols = query.protocols;
# 136 "mlhttp/websocket.ml"
      r_host = query.host;
# 137 "mlhttp/websocket.ml"
      r_origin = query.origin;
# 138 "mlhttp/websocket.ml"
      challenge }
# 139 "mlhttp/websocket.ml"
    
# 140 "mlhttp/websocket.ml"
  let string_of_response response =
# 141 "mlhttp/websocket.ml"
    let headers = "HTTP/1.1 101 WebSocket Protocol Handshake\nUpgrade: WebSocket\nConnection: Upgrade" in
# 142 "mlhttp/websocket.ml"
    let origin = match response.r_origin with
# 143 "mlhttp/websocket.ml"
      | Some o -> "Sec-WebSocket-Origin: " ^ o
# 144 "mlhttp/websocket.ml"
      | None   -> "" in
# 145 "mlhttp/websocket.ml"
    let location = match response.r_host with
# 146 "mlhttp/websocket.ml"
      | Some o -> "Sec-WebSocket-Location: " ^ o
# 147 "mlhttp/websocket.ml"
      | None   -> "" in
# 148 "mlhttp/websocket.ml"
    String.concat "\n" [ headers ; origin ; location ; "\r\n\r" ; response.challenge ]
# 149 "mlhttp/websocket.ml"

# 150 "mlhttp/websocket.ml"
  let process str =
# 151 "mlhttp/websocket.ml"
    query_of_string str >>
# 152 "mlhttp/websocket.ml"
    response_of_query >>
# 153 "mlhttp/websocket.ml"
    string_of_response
# 154 "mlhttp/websocket.ml"
end
# 155 "mlhttp/websocket.ml"

# 156 "mlhttp/websocket.ml"
module Server(IP:Ipv4.UP)(TCP:Tcp.UP) = struct
# 157 "mlhttp/websocket.ml"

# 158 "mlhttp/websocket.ml"
  type state =
# 159 "mlhttp/websocket.ml"
  | Connecting
# 160 "mlhttp/websocket.ml"
  | Open
# 161 "mlhttp/websocket.ml"
  | Closing
# 162 "mlhttp/websocket.ml"
  | Closed
# 163 "mlhttp/websocket.ml"

# 164 "mlhttp/websocket.ml"
  type connection = {
# 165 "mlhttp/websocket.ml"
    host : string;
# 166 "mlhttp/websocket.ml"
    port : int;
# 167 "mlhttp/websocket.ml"
    resource : string option;
# 168 "mlhttp/websocket.ml"
    secure : bool;
# 169 "mlhttp/websocket.ml"
  }
# 170 "mlhttp/websocket.ml"
       
# 171 "mlhttp/websocket.ml"
  type t = {
# 172 "mlhttp/websocket.ml"
    ip : IP.t;
# 173 "mlhttp/websocket.ml"
    tcp : TCP.t;
# 174 "mlhttp/websocket.ml"
    listeners : (Mpl.Ipv4.o -> Mpl.Tcp.o -> Mpl.Websocket.o -> unit Lwt.t) list;
# 175 "mlhttp/websocket.ml"
  }
# 176 "mlhttp/websocket.ml"
  
# 177 "mlhttp/websocket.ml"

# 178 "mlhttp/websocket.ml"
  let output t ~dest_ip ws =
# 179 "mlhttp/websocket.ml"
   match ws.ready_state with
# 180 "mlhttp/websocket.ml"
   | Connecting -> raise Invalid_state_err
# 181 "mlhttp/websocket.ml"
   | Closing | Closed -> ()
# 182 "mlhttp/websocket.ml"
   | Open -> (* TODO *) ()
# 183 "mlhttp/websocket.ml"
      
# 184 "mlhttp/websocket.ml"

# 185 "mlhttp/websocket.ml"
  let close t =
# 186 "mlhttp/websocket.ml"
   match ws.ready_state with
# 187 "mlhttp/websocket.ml"
   | Closing | Closed -> ()
# 188 "mlhttp/websocket.ml"
   | Connecting ->
# 189 "mlhttp/websocket.ml"
	   ws.ready_state <- Closing;
# 190 "mlhttp/websocket.ml"
	   (* TODO: fail the websocket connection *)
# 191 "mlhttp/websocket.ml"
	   ws.ready_state <- Closed
# 192 "mlhttp/websocket.ml"
   | Open ->
# 193 "mlhttp/websocket.ml"
	   ws.ready_state <- Closed
# 194 "mlhttp/websocket.ml"
end
