(*
 * Copyright (c) 2010 http://github.com/barko 00336ea19fcb53de187740c490f764f4
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

module Rx : sig
  type t

  val create : max_size:int32 -> wnd:Window.t -> t
  val add_r : t -> Bitstring.t option -> unit Lwt.t
  val take_l : t -> Bitstring.t option Lwt.t
  val cur_size : t -> int32
  val max_size : t -> int32
  val monitor: t -> int32 Lwt_mvar.t -> unit
end

module Tx : sig
  type t

  val create: max_size:int32 -> wnd:Window.t -> txq:Segment.Tx.q -> t
  val available: t -> int32
  val wait_for: t -> int32 -> unit Lwt.t
  val wait_for_flushed: t -> unit Lwt.t
  val write: t -> Bitstring.t -> unit Lwt.t
  val write_nodelay: t -> Bitstring.t -> unit Lwt.t
  val free: t -> int -> unit Lwt.t
end
