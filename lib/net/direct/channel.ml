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

(* Buffered reading and writing over the flow API *)
open Lwt
open Printf
open Nettypes

module Make(Flow:FLOW) : 
  (CHANNEL with type src = Flow.src
            and type dst = Flow.dst
            and type mgr = Flow.mgr)  = struct

  type flow = Flow.t
  type src = Flow.src
  type dst = Flow.dst
  type mgr = Flow.mgr

  type t = {
    flow: flow;
    mutable ibuf: Bitstring.t;
    mutable obuf: Bitstring.t list;
    abort_t: unit Lwt.t;
    abort_u: unit Lwt.u;
  }

  exception Closed

  let create flow =
    let ibuf = "",0,0 in
    let obuf = [] in
    let abort_t, abort_u = Lwt.task () in
    { ibuf; obuf; flow; abort_t; abort_u }

  let ibuf_refill t = 
    match_lwt Flow.read t.flow with
    |Some buf ->
      t.ibuf <- buf;
      return ()
    |None ->
      fail Closed

  (* Read one character from the input channel *)
  let rec read_char t =
    bitmatch t.ibuf with
    | { c:8; rest:-1:bitstring } ->
        t.ibuf <- rest;
        return (Char.chr c)
    | { rest:-1:bitstring } when Bitstring.bitstring_length rest = 0 ->
        ibuf_refill t >>
        read_char t

  (* Read up to len characters from the input channel
     and at most a full view. If not specified, read all *)
  let read_some ?len t =
    lwt () = if Bitstring.bitstring_length t.ibuf = 0 then
      ibuf_refill t else return () in
    let avail = Bitstring.bitstring_length t.ibuf in
    let len = match len with |Some len -> len * 8 |None -> avail in
    if len < avail then begin 
      let r = Bitstring.subbitstring t.ibuf 0 len in
      t.ibuf <- Bitstring.subbitstring t.ibuf len (avail-len);
      return r
    end else begin 
      let r = t.ibuf in
      t.ibuf <- "",0,0;
      return r
    end
    
  (* Read up to len characters from the input channel as a 
     stream (and read all available if no length specified *)
  let read_stream ?len t =
    Lwt_stream.from (fun () ->
      try_lwt
        lwt v = read_some ?len t in
        return (Some v)
      with Closed ->
        return None
    )
 
  (* Read until a character is found *)
  let read_until t ch =
    lwt () = if Bitstring.bitstring_length t.ibuf = 0 then
      ibuf_refill t else return () in
    try_lwt
      let buf,off,len = t.ibuf in
      let idx = (String.index_between buf (off/8) ((off+len)/8) ch) * 8 in
      let rlen = idx - off in
      (bitmatch t.ibuf with
      | { _:8; rest:-1:bitstring } when rlen = 0 ->
          t.ibuf <- rest;
          return (true, Bitstring.empty_bitstring)
      | { r:rlen:bitstring; _:8; rest:-1:bitstring } ->
          t.ibuf <- rest;
          return (true, r)
      | { _ } ->
          printf "Flow: unexpected bitmatch failure in read_until\n%!";
          exit 1
      )
    with Not_found -> begin
      let r = t.ibuf in
      t.ibuf <- "",0,0; 
      return (false,r)
    end

  (* This reads a line of input, which is terminated either by a CRLF
     sequence, or the end of the channel (which counts as a line).
     @return Returns a stream of views that terminates at EOF.
     @raise Closed to signify EOF  *)
  let read_crlf t =
    let rec get acc =
      match_lwt read_until t '\n' with
      |(false, v) ->
        get (v :: acc)
      |(true, v) -> begin
        (* chop the CR if present *)
        let vlen = Bitstring.bitstring_length v in
        let v = bitmatch v with
          | { rest:vlen-8:bitstring; 13:8 } when vlen >= 8 -> rest
          | { _ } -> v in
        return (v :: acc) 
      end
    in
    lwt res = get [] >|= List.rev in
    return (Bitstring.concat res)
    
  (* Output functions *)

  let rec flush t =
    let l = List.rev t.obuf in
    lwt res = Flow.writev t.flow l in
    t.obuf <- [res];
    if Bitstring.bitstring_length res > 0 then
      flush t
    else
      return ()

  (* Stonkingly inefficient *)
  let write_char t ch =
    t.obuf <- ((String.make 1 ch),0,8) :: t.obuf;
    return ()

  let write_bitstring t buf =
    t.obuf <- buf :: t.obuf;
    return ()

  let write_string t buf =
    write_bitstring t (Bitstring.bitstring_of_string buf)

  let write_line t buf =
    write_string t buf >>
    write_char t '\n'

  let close t =
    flush t >>
    Flow.close t.flow

  let connect mgr ?src dst fn =
    Flow.connect mgr ?src dst (fun f -> fn (create f))

  let listen mgr src fn =
    Flow.listen mgr src (fun dst f -> fn dst (create f))

end

module TCPv4 = Make(Flow.TCPv4)
module Shmem = Make(Flow.Shmem)

type t =
  | TCPv4 of TCPv4.t
  | Shmem of Shmem.t

let read_char = function
  | TCPv4 t -> TCPv4.read_char t
  | Shmem t -> Shmem.read_char t

let read_until = function
  | TCPv4 t -> TCPv4.read_until t
  | Shmem t -> Shmem.read_until t

let read_some ?len = function
  | TCPv4 t -> TCPv4.read_some ?len t
  | Shmem t -> Shmem.read_some ?len t

let read_stream ?len = function
  | TCPv4 t -> TCPv4.read_stream ?len t
  | Shmem t -> Shmem.read_stream ?len t

let read_crlf = function
  | TCPv4 t -> TCPv4.read_crlf t
  | Shmem t -> Shmem.read_crlf t

let write_char = function
  | TCPv4 t -> TCPv4.write_char t
  | Shmem t -> Shmem.write_char t

let write_string = function
  | TCPv4 t -> TCPv4.write_string t
  | Shmem t -> Shmem.write_string t

let write_bitstring = function
  | TCPv4 t -> TCPv4.write_bitstring t
  | Shmem t -> Shmem.write_bitstring t

let write_line = function
  | TCPv4 t -> TCPv4.write_line t
  | Shmem t -> Shmem.write_line t

let flush = function
  | TCPv4 t -> TCPv4.flush t
  | Shmem t -> Shmem.flush t

let close = function
  | TCPv4 t -> TCPv4.close t
  | Shmem t -> Shmem.close t

let connect mgr = function
  |`TCPv4 (src, dst, fn) ->
     TCPv4.connect mgr ?src dst (fun t -> fn (TCPv4 t))
  |`Shmem (src, dst, fn) ->
     Shmem.connect mgr ?src dst (fun t -> fn (Shmem t))
  |_ -> fail (Failure "unknown protocol")

let listen mgr = function
  |`TCPv4 (src, fn) ->
     TCPv4.listen mgr src (fun dst t -> fn dst (TCPv4 t))
  |`Shmem (src, fn) ->
     Shmem.listen mgr src (fun dst t -> fn dst (Shmem t))
  |_ -> fail (Failure "unknown protocol")
