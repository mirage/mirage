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
    type t
    val empty : t
    val iter : (OS.Istring.View.t -> unit) -> t -> unit
    val to_string : t -> string
    val input : seg:seg -> rcv_nxt:int32 -> segs:t -> t * t
  end

module Tx :
  sig
    type seg
    val seg : ?urg:bool -> ?fin:bool -> Mpl.Tcp.o OS.Istring.View.data -> seg
    type t = seg list
    val empty : t
    val output : int -> t -> seg option * t
    val to_string : t -> string
    val is_empty : t -> bool
    val with_fin : seg -> seg
    val fin : seg -> bool
    val data : seg -> Mpl.Tcp.o OS.Istring.View.data
    val urg : seg -> bool
  end
