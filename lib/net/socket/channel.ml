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

module type CHAN = sig
  type flow
  type chan
  val t: flow -> chan
  val read_until: chan -> char -> OS.Istring.View.t Lwt_sequence.t Lwt.t
end

module Make(Flow:Nettypes.FLOW) : CHAN = struct
  type flow = Flow.t

  type chan = {
    flow: flow;
    ibuf: OS.Istring.View.t Lwt_sequence.t;
    obuf: OS.Istring.View.t Lwt_sequence.t;
    mutable ilen: int;
    mutable ipos: int;
    mutable opos: int;
    abort_t: unit Lwt.t;
    abort_u: unit Lwt.u;
  }

  exception Closed

  let t flow =
    let ibuf = Lwt_sequence.create () in
    let obuf = Lwt_sequence.create () in
    let ilen = 0 in
    let ipos = 0 in
    let opos = 0 in
    let abort_t, abort_u = Lwt.task () in
    { ibuf; obuf; ilen; ipos; opos; flow; abort_t; abort_u }

  (* Ensure the input buffer has enough for our purposes *)
  let rec ibuf_need t amt =
    if t.ilen < t.ipos + amt then begin
      lwt res = Flow.read t.flow in
      match res with
      |None -> fail Closed
      |Some view ->
        let _ = Lwt_sequence.add_r view t.ibuf in
        t.ilen <- OS.Istring.View.length view + t.ilen;
        ibuf_need t amt
    end else
      return (Lwt_sequence.peek_r t.ibuf)

  (* Increment the input buffer position *)
  let rec ibuf_incr t amt =
    let buf = Lwt_sequence.peek_r t.ibuf in
    let buf_len = OS.Istring.View.length buf in
    let ipos = t.ipos in
    if (ipos + amt) >= buf_len then begin
      (* This buf has been consumed. Free it *)
      let _ = Lwt_sequence.take_l t.ibuf in
      t.ilen <- t.ilen - buf_len;
      t.ipos <- 0;
      if ipos + amt - buf_len > 0 then begin
        (* More buffers need removing *)
        ibuf_incr t (ipos + amt - buf_len)
      end
    end else begin
      (* Continue to partially consume head buf *)
      t.ipos <- t.ipos + amt
    end

  let read_char t =
    lwt view = ibuf_need t 1 in
    let ch = OS.Istring.View.to_char view t.ipos in
    ibuf_incr t 1;
    return ch

  (* Read until a character is encountered *)
  let read_until t ch =
    (* require at least one character to start with *)
    lwt view = ibuf_need t 1 in
    match OS.Istring.View.scan_char view t.ipos ch with
    |(-1) -> 
      (* slow path, need another segment *)
      let segs = Lwt_sequence.create () in
      let headview = Lwt_sequence.take_l t.ibuf in
      let start_pos = t.ipos in
      let start_len = OS.Istring.View.length headview - start_pos in
      t.ipos <- 0;
      t.ilen <- t.ilen - (OS.Istring.View.length headview);
      let rec scan () =
        lwt view = ibuf_need t 1 in
        match OS.Istring.View.scan_char view 0 ch with
        |(-1) ->
          let view = Lwt_sequence.take_l t.ibuf in
          let _ = Lwt_sequence.add_r view segs in
          t.ilen <- t.ilen - (OS.Istring.View.length view);
          scan ()
        |idx ->
          (* Add head sub-view to the result segment list *)
          let _ = Lwt_sequence.add_l (OS.Istring.View.sub headview start_pos start_len) segs in
          (* Append last subview in *)
          let _ = Lwt_sequence.add_r (OS.Istring.View.sub view 0 idx) segs in
          ibuf_incr t (idx+1);
          return segs
      in scan ()
    |idx ->
      let seg = Lwt_sequence.create () in
      let len = idx - t.ipos in
      if len > 0 then begin
        let _ = Lwt_sequence.add_l (OS.Istring.View.sub view t.ipos (idx-t.ipos)) in
        ibuf_incr t (len+1);
      end;
      return seg
end
