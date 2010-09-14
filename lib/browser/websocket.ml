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

exception Not_supported

module Ws = struct
  type t
  external supported : unit -> bool = "@ws_supported"
  external send : t -> string -> unit = "@ws_send"
  external create : string -> int -> (string -> unit) -> t = "@ws_create" (* url * evtch * callback *)
end

(* Each connection has a queue of incoming messages, waiting for ocaml readers to call [read] *)
type t = {
  messages: string Queue.t;
  evtch: int;
  ws: Ws.t;
  cond: unit Lwt_condition.t;
}

let create url evtch =
  if Ws.supported () then begin
    let messages = Queue.create () in
    let callback msg = Queue.push msg messages in
    let cond = Lwt_condition.create () in
    Activations.register evtch (Activations.Event_condition cond);
    let ws = Ws.create url evtch callback in
    (* Let's wait that the 'onopen' callback wakes us *)
    Console.printf "[%d] waiting for the connection to be opened propely ..." evtch;
    Lwt_condition.wait cond >> 
    return (Console.printf "[%d] OK" evtch) >>
    return { messages; evtch; ws; cond }
  end else
    Lwt.fail Not_supported

let sync_write t str =
  Ws.send t.ws str;
  return ()

let write t str =
  Ws.send t.ws str

let rec read t =
  if Queue.is_empty t.messages then
    Lwt_condition.wait t.cond >>
    read t
  else
    return (Queue.pop t.messages)

