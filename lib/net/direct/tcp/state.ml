(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
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

open Printf

type i = [
  | `syn
  | `fin
]

type chan = 
  | Closed
  | Established
  | Shutdown

type t = {
  mutable rx: chan;
  mutable tx: chan;
}

exception Bad_transition of (chan * i)

let t () = { rx=Closed; tx=Closed }

let rx t = t.rx
let tx t = t.tx

let tick chan (i:i) =
  match chan, i with
  | Closed, `syn -> Established
  | Established, `fin -> Shutdown
  | x,_ -> x

let i_to_string = function
  | `fin -> "fin"
  | `syn -> "syn"

let chan_to_string = function
  | Closed -> "Closed"
  | Established -> "Established"
  | Shutdown -> "Shutdown"

let to_string t =
  sprintf "{ tx=%s rx=%s }" (chan_to_string t.tx) (chan_to_string t.rx)

let tick_rx t (i:i) =
  t.rx <- tick t.rx i

let tick_tx t (i:i) =
  t.tx <- tick t.tx i
