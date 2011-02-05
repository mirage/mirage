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

(* Flow library that uses the TCP/UDP Net library *)

open Lwt
open OS
open Nettypes

exception Not_implemented

type t = Tcp.Pcb.pcb

let connect t =
  fail Not_implemented 

let close t =
  Tcp.Pcb.close t

let read t =
  Tcp.Pcb.read t

let write t view =
  let len = Int32.of_int (OS.Istring.View.length view) in
  Tcp.Pcb.write_wait_for t len >>
  Tcp.Pcb.write t (`Frag view)

let listen mgr ?addr ~port fn =
  Manager.listen mgr (`TCP (addr, port, fn)) 
  
let connect mgr ~addr ~port fn =
  Manager.connect mgr (`TCP (addr, port, fn))
