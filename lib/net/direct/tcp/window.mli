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


type t 

val t : rx_wnd_scale:int -> tx_wnd_scale:int -> rx_wnd:int ->
  tx_wnd:int -> rx_isn:Sequence.t -> tx_mss:int option -> t

val valid : t -> Sequence.t -> bool

val rx_advance : t -> int -> unit
val rx_advance_inseq : t -> int -> unit
val rx_nxt : t -> Sequence.t
val rx_nxt_inseq : t -> Sequence.t
val rx_nxt_set_lastack : t -> Sequence.t
val rx_pending_ack : t -> bool

val tx_advance : t -> int -> unit
val tx_ack: t -> Sequence.t -> unit
val tx_nxt : t -> Sequence.t
val tx_una : t -> Sequence.t
val tx_mss : t -> int

(* rx_wnd: Size of traffic we are willing to accept *)
val rx_wnd : t -> int32
val set_rx_wnd : t -> int32 -> unit

(* tx_wnd: Size of traffic other side is willing to accept *)
val tx_wnd : t -> int32
(* tx_available: Size of traffic we can currently send after
                 accounting for congestion *)
val tx_available : t -> int32
val set_tx_wnd : t -> int -> unit

val alert_fast_rexmit : t -> Sequence.t -> unit
