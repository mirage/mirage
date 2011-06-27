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
    val make: sequence:Sequence.t -> fin:bool -> syn:bool -> ack:bool ->
      ack_number:Sequence.t -> window:int -> data:Bitstring.t -> seg

    type q
    val q : rx_data:Bitstring.t list option Lwt_mvar.t ->
      wnd:Window.t ->
      tx_ack:Sequence.t Lwt_mvar.t -> 
      tx_wnd_update:int Lwt_mvar.t -> q
    val to_string : q -> string
    val is_empty : q -> bool
    val input : q -> seg -> unit Lwt.t
  end

(* Pre-transmission queue *)
module Tx :
  sig

    type flags = |No_flags |Syn |Fin |Rst

    type xmit = flags:flags -> wnd:Window.t -> options:Options.ts ->
      Bitstring.t -> Bitstring.t Lwt.t

    type q

    val q : xmit:xmit -> wnd:Window.t ->
      rx_ack:Sequence.t Lwt_mvar.t ->
      tx_ack:Sequence.t Lwt_mvar.t -> q * unit Lwt.t

    val output : ?flags:flags -> ?options:Options.ts -> q -> Bitstring.t -> unit Lwt.t
   
  end
