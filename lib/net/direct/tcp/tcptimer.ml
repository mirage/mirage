(*
 * Copyright (c) 2012 Balraj Singh <bs375@cl.cam.ac.uk>
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

type tr =
  | Stoptimer
  | Continue of Sequence.t
  | ContinueSetPeriod of (float * Sequence.t)

type t = {
  expire: (Sequence.t -> tr);
  mutable period: float;
  mutable running: bool;
  }

let t ~period ~expire =
  let running = false in
  {period; expire; running}


let rec timerloop t s =
  OS.Time.sleep t.period >>
  match t.expire s with
  | Stoptimer ->
      t.running <- false;
      return ()
  | Continue d ->
      timerloop t d
  | ContinueSetPeriod (p, d) ->
      t.period <- p;
      timerloop t d

  
let period t = t.period

let start t ?(p=(period t)) s =
  if not t.running then begin
    t.period <- p;
    t.running <- true;
    let _ = timerloop t s in
    return ()
  end else 
    return ()
