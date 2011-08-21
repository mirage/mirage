(*
 * Copyright (c) 2010-2011 Anil Madhavapeddy <anil@recoil.org>
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

(* Flow stubs *)

open Nettypes
open Lwt
open OS

type ipv4_src = ipv4_addr option * int
type ipv4_dst = ipv4_addr * int

exception Listen_error of string
exception Accept_error of string
exception Connect_error of string
exception Read_error of string
exception Write_error of string
exception Not_implemented

let close t = fail Not_implemented

let close_on_exit t fn =
  try_lwt 
    lwt x = fn t in
    close t >>
    return x
  with exn -> 
    close t >>
    fail exn

let write t (buf,off,len) = fail Not_implemented
let read t = fail Not_implemented
let writev t views = fail Not_implemented

module TCPv4 = struct
  type t 
  type mgr = Manager.t
  type src = ipv4_addr option * int
  type dst = ipv4_addr * int

  let read = read
  let writev = writev
  let close = close
  let write = write

  let listen mgr src fn = fail Not_implemented
  let connect mgr ?src ((addr,port):ipv4_dst) (fn: t -> 'a Lwt.t) = fail Not_implemented
end

type t =
  | TCPv4 of TCPv4.t

type mgr = Manager.t

let read = function
  | TCPv4 t -> TCPv4.read t

let write = function
  | TCPv4 t -> TCPv4.write t

let writev = function
  | TCPv4 t -> TCPv4.writev t

let close = function
  | TCPv4 t -> TCPv4.close t

let connect mgr = function
  |`TCPv4 (src, dst, fn) ->
     TCPv4.connect mgr ?src dst (fun t -> fn (TCPv4 t))
  |_ -> fail (Failure "unknown protocol")

let listen mgr = function
  |`TCPv4 (src, fn) ->
     TCPv4.listen mgr src (fun dst t -> fn dst (TCPv4 t))
  |_ -> fail (Failure "unknown protocol")

