(*
 * Copyright (c) 2011 Anil Madhavapeddy <anil@recoil.org>
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

open Lwt
open Printf
open Types

type http_req = {
  req_meth: meth;
  req_url: string;
  req_headers: (string * string) list;
}

type http_res = {
  res_status: status;
  res_headers: (string * string) list;
}

module type WIRE = sig
  type chan
 
  type tx
  type rx
 
  type 'a req
  type 'a res

  val req_marshal: chan -> tx req -> unit Lwt.t
  val req_unmarshal : chan -> rx req Lwt.t
 
  val res_marshal: chan -> tx res Lwt.t 
  val res_unmarshal: chan -> rx res Lwt.t

end

type mgr = Proxy.t

module HTTP_wire = struct

  type tx = (Net.Channel.t -> unit Lwt.t) option
  type rx = OS.Istring.t Lwt_stream.t
  type 'a req = http_req * 'a
  type 'a res = http_res * 'a

  let meth_to_string = function
    |`GET -> "GET"
    |`HEAD -> "HEAD"
    |`POST -> "POST"
    |`DELETE -> "DELETE"

  let req_marshal chan (req,body) =
    Net.Channel.write_string chan (sprintf "%s %s HTTP/1.1\r\n" (meth_to_string req.req_meth) req.req_url) >>
    Lwt_list.iter_s (fun (k,v) -> Net.Channel.write_string chan (sprintf "%s: %s\r\n" k v)) req.req_headers >>
    Net.Channel.write_string chan "\r\n" >>
    match body with
    |None -> Net.Channel.flush chan
    |Some fn -> fn chan >> Net.Channel.flush chan

  let req_unmarshal chan =
    fail (Failure "not implemented")

  let res_marshal chan res =
    fail (Failure "not implemented")
  
  let res_unmarshal chan =
    let read_line () =
      let stream = Channel.read_crlf chan in 
      lwt ts = OS.Istring.ts_of_stream stream in
      return (OS.Istring.ts_to_string ts)
    in
    lwt (_, res_status) = Parser.parse_response_fst_line read_line in
    lwt res_headers = Parser.parse_headers read_line in
    let res_body =
      let len = Parser.parse_content_range res_headers in
      Lwt_stream.from (fun () -> Channel.read_view ?len chan) 
    in
    return ({res_headers; res_status}, res_body)

end

module TCPv4_HTTP = HTTP_wire(Channel.TCPv4)
module Pipe_HTTP = HTTP_wire(Channel.Pipe)
