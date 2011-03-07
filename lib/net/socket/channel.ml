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
    mutable ibuf: OS.Istring.t option;
    mutable ipos: int;
    mutable obuf: OS.Istring.t option;
    mutable opos: int;
    abort_t: unit Lwt.t;
    abort_u: unit Lwt.u;
  }

  exception Closed

  let create flow =
    let ibuf = None in
    let obuf = None in
    let ipos = 0 in
    let opos = 0 in
    let abort_t, abort_u = Lwt.task () in
    { ibuf; obuf; ipos; opos; flow; abort_t; abort_u }

  (* Increment the input buffer position *)
  let ibuf_incr t amt =
    let newpos = t.ipos + amt in 
    match t.ibuf with
    |Some view ->
      if newpos >= OS.Istring.View.length view then begin
        t.ibuf <- None;
        t.ipos <- 0;
      end else
        t.ipos <- newpos;
    |None -> assert false

  (* Fill the input buffer with a view and return it,
     or the existing one if already there *)
  let ibuf_fill t =
    match t.ibuf with
    |Some buf ->
      return buf
    |None -> begin
      Flow.read t.flow >>= function
      |Some buf as x ->
        t.ibuf <- x;
        return buf
      |None ->
        fail Closed
    end

  (* Read one character from the input channel *)
  let read_char t =
    lwt buf = ibuf_fill t in
    let ch = OS.Istring.View.to_char buf t.ipos in
    ibuf_incr t 1;
    return ch

  (* Read up to len characters from the input channel
     and at most a full view. If not specified, read all *)
  let read_view ?len t =
    lwt buf = ibuf_fill t in
    (* Read at most one view *)
    let n = match len with
      |Some len -> min (OS.Istring.View.length buf - t.ipos) len 
      |None -> OS.Istring.View.length buf - t.ipos in
    let v = OS.Istring.View.sub buf t.ipos n in
    ibuf_incr t n;
    return v
    
  (* Read up to len characters from the input channel as a 
     stream (and read all available if no length specified *)
  let read_stream ?len t =
    Lwt_stream.from (fun () ->
      try_lwt
        lwt v = read_view ?len t in
        return (Some v)
      with Closed ->
        return None
    )
  
  (* Read until a character is encountered. This can also
     be a short read, and return a short view that does
     not yet have the character.
     @return (bool * view option) where bool=character found
      along with the view portion consumed.
     @raise Closed on EOF
   *)
  let read_until t ch =
    lwt buf = ibuf_fill t in
    match OS.Istring.View.scan_char buf t.ipos ch with
    |(-1) ->  (* not found, so return the partial view *)
      let v = OS.Istring.View.sub buf t.ipos (OS.Istring.View.length buf - t.ipos) in
      return (false, Some v)
    |idx ->
      let len = idx - t.ipos in
      if len >= 0 then begin
        let v = OS.Istring.View.sub buf t.ipos (idx-t.ipos) in
        ibuf_incr t (len+1);
        return (true, Some v)
      end else begin (* Consume just the divider character *)
        ibuf_incr t 1;
        return (true, None)
      end

  (* Read a "chunk" of data (where the chunk size is dependent on the
     underlying protocol and available data, and raise Closed when EOF *)
  let read_opt t =
    lwt buf = ibuf_fill t in
    let len = OS.Istring.View.length buf - t.ipos in
    let v = OS.Istring.View.sub buf t.ipos len in
    ibuf_incr t len;
    return v

  (* This reads a line of input, which is terminated either by a CRLF
     sequence, or the end of the channel (which counts as a line).
     @return Returns a stream of views that terminates at EOF.
     @raise Closed to signify EOF  *)
  let read_crlf t =
    let fin = ref false in
    Lwt_stream.from (fun () ->
      match !fin with
      |true -> return None
      |false -> begin
        read_until t '\n' >>= function
        |true, None -> return None
        |false, None -> assert false
        |false, Some v -> return (Some v) (* Continue scanning *)
        |true, Some v -> begin (* Found (CR?)LF *)
          fin := true;
          (* chop the CR if present *)
          let vlen = OS.Istring.View.length v in
          match OS.Istring.View.to_char v (vlen - 1) with
          |'\r' ->
            if vlen > 1 then
              return (Some (OS.Istring.View.(sub v 0 (vlen-1))))
            else
              return None
          |_ ->
            return (Some v)
        end
      end
    )
    
  (* Output functions *)

  let flush t =
    match t.obuf with
    |Some v ->
      Flow.write t.flow v >>
      return (t.obuf <- None)
    |None -> return ()

  let get_obuf t =
    match t.obuf with 
    |None ->
        let buf = OS.Istring.Raw.alloc () in
        let view = OS.Istring.View.t buf 0 in
        t.obuf <- Some view;
        view
      |Some v -> v

  let write_char t ch =
    let view = get_obuf t in
    let viewlen = OS.Istring.View.length view in
    OS.Istring.View.set_char view viewlen ch;
    OS.Istring.View.seek view (viewlen+1);
    if OS.Istring.View.length view = 4096 then
      flush t
    else
      return ()

  let rec write_string t buf =
    let view = get_obuf t in
    let buflen = String.length buf in
    let viewlen = OS.Istring.View.length view in
    let remaining = 4096 - viewlen in
    if buflen <= remaining then begin
      OS.Istring.View.set_string view viewlen buf;
      OS.Istring.View.seek view (viewlen + buflen);
      if viewlen = 4096 then flush t else return ();
    end else begin
      (* String is too big for one istring, so split it *)
      let b1 = String.sub buf 0 remaining in
      let b2 = String.sub buf remaining (buflen - remaining) in
      OS.Istring.View.set_string view viewlen b1;
      OS.Istring.View.seek view (viewlen + remaining);
      flush t >>
      write_string t b2
    end

  let write_view t view =
    (* First, flush any outstanding string writes *)
    lwt () = match t.obuf with 
    |Some x -> flush t
    |None -> return () in
    Flow.write t.flow view

  let write_views t views =
    (* First, flush any outstanding string writes *)
    lwt () = match t.obuf with 
    |Some x -> flush t
    |None -> return () in
    Lwt_stream.iter_s (Flow.write t.flow) views
    
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
module Pipe = Make(Flow.Pipe)

type t =
  | TCPv4 of TCPv4.t
  | Pipe of Pipe.t

let read_char = function
  | TCPv4 t -> TCPv4.read_char t
  | Pipe t -> Pipe.read_char t

let read_until = function
  | TCPv4 t -> TCPv4.read_until t
  | Pipe t -> Pipe.read_until t

let read_view ?len = function
  | TCPv4 t -> TCPv4.read_view ?len t
  | Pipe t -> Pipe.read_view ?len t

let read_stream ?len = function
  | TCPv4 t -> TCPv4.read_stream ?len t
  | Pipe t -> Pipe.read_stream ?len t

let read_crlf = function
  | TCPv4 t -> TCPv4.read_crlf t
  | Pipe t -> Pipe.read_crlf t

let write_char = function
  | TCPv4 t -> TCPv4.write_char t
  | Pipe t -> Pipe.write_char t

let write_string = function
  | TCPv4 t -> TCPv4.write_string t
  | Pipe t -> Pipe.write_string t

let write_line = function
  | TCPv4 t -> TCPv4.write_line t
  | Pipe t -> Pipe.write_line t

let write_view = function
  | TCPv4 t -> TCPv4.write_view t
  | Pipe t -> Pipe.write_view t

let write_views = function
  | TCPv4 t -> TCPv4.write_views t
  | Pipe t -> Pipe.write_views t

let flush = function
  | TCPv4 t -> TCPv4.flush t
  | Pipe t -> Pipe.flush t

let close = function
  | TCPv4 t -> TCPv4.close t
  | Pipe t -> Pipe.close t

let connect mgr = function
  |`TCPv4 (src, dst, fn) ->
     TCPv4.connect mgr ?src dst (fun t -> fn (TCPv4 t))
  |`Pipe (src, dst, fn) ->
     Pipe.connect mgr ?src dst (fun t -> fn (Pipe t))
  |_ -> fail (Failure "unknown protocol")

let listen mgr = function
  |`TCPv4 (src, fn) ->
     TCPv4.listen mgr src (fun dst t -> fn dst (TCPv4 t))
  |`Pipe (src, fn) ->
     Pipe.listen mgr src (fun dst t -> fn dst (Pipe t))
  |_ -> fail (Failure "unknown protocol")
