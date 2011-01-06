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

module Rx :
  sig
    type seg
    val seg : Mpl.Tcp.o -> seg
    type q
    val q : unit -> q
    val to_string : q -> string
    val iter : (seg -> unit) -> q -> unit
    val view : seg -> OS.Istring.View.t
    val syn: seg -> bool
    val ack: seg -> Tcp_sequence.t option
    val input : wnd:Tcp_window.t -> seg:seg -> q -> q
  end

(* Pre-transmission queue *)
module Tx :
  sig

    type seg
    type q
    val seg : ?syn:bool -> ?ack:Tcp_sequence.t option ->
      ?fin:bool -> Mpl.Tcp.o OS.Istring.View.data -> seg
    val q : unit -> q

    val ack: seg -> Tcp_sequence.t option
    val fin: seg -> bool
    val syn: seg -> bool
    val data: seg -> Mpl.Tcp.o OS.Istring.View.data

    (* Operations on the pre-transmission queue *)
    val coalesce : mss:int -> q -> seg option
    val queue : seg -> q -> unit Lwt.t
   
  end

(* Retransmission queue *)
module Rtx :
  sig
    type seg
    type q
    val seg : Mpl.Tcp.o -> seg
    val q : unit -> q

    val queue : wnd:Tcp_window.t -> seg -> q -> unit Lwt.t

    (* Indicate that a range of sequence numbers have been ACKed and
       can be removed *)
    val mark_ack : int Lwt_condition.t -> q -> Tcp_sequence.t -> Tcp_sequence.t -> unit
  end
