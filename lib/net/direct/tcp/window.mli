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

val t : rx_wnd_scale:int -> tx_wnd_scale:int -> rx_wnd:int -> tx_wnd:int -> rx_isn:Sequence.t -> t

val valid : t -> Sequence.t -> bool

val rx_advance : t -> int -> unit
val rx_nxt : t -> Sequence.t

val tx_advance : t -> int -> unit
val tx_ack: t -> Sequence.t -> unit
val tx_nxt : t -> Sequence.t
val tx_una : t -> Sequence.t
val tx_mss : t -> int32

(* RCV.WND: Size of traffic we are willing to accept *)
val rx_wnd : t -> int32
val set_rx_wnd : t -> int32 -> unit

(* SND.WND: Size of traffic we are allowed to send *)
val tx_wnd : t -> int32
val set_tx_wnd : t -> int -> unit
