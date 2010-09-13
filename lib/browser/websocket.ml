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

open Lwt 

module Ws = struct
  type t
  external send : t -> string -> unit = "@ws_send"
  external create : string -> int -> (string -> unit) -> t = "@ws_create" (* url * evtch * callback *)
end

(* very inefficient ring buffer *)
type t = {
  mutable buffer: Buffer.t;
  mutable current: int;
  evtch: int;
  ws: Ws.t;
  cond: unit Lwt_condition.t;
}

let buffer_size = 1024 * 8

let create url evtch =
  let buffer = Buffer.create buffer_size in
  let current = 0 in
  let ws = Ws.create url evtch (Buffer.add_string buffer) in
  let cond = Lwt_condition.create () in
  Activations.register evtch (Activations.Event_condition cond);
  { buffer; current; evtch; ws; cond }

let sync_write t str =
  Ws.send t.ws str;
  return ()

let write t str =
  Ws.send t.ws str

(* XXX: not efficient at all *)
let shrink_buffer t =
  if t.current > buffer_size then begin
    Console.log "Shrinking the read buffer";
    let remaining = Buffer.sub t.buffer t.current (Buffer.length t.buffer - t.current) in
    t.buffer <- Buffer.create buffer_size;
    Buffer.add_string t.buffer remaining;
    t.current <- 0
  end

let read t length =
  Lwt_condition.wait t.cond >>
  let len = min (Buffer.length t.buffer - t.current) length in
  let res = Buffer.sub t.buffer t.current len in
  t.current <- t.current + len;
  shrink_buffer t;
  return (res, len)


